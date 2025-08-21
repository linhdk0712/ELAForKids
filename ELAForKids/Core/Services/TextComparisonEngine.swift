import Foundation
import NaturalLanguage

// MARK: - Text Comparison Engine
final class TextComparisonEngine: TextComparisonProtocol {
    
    // MARK: - Properties
    private let vietnameseTokenizer = NLTokenizer(unit: .word)
    private let minimumWordSimilarity: Float = 0.7
    private let levenshteinThreshold: Int = 2
    
    init() {
        vietnameseTokenizer.setLanguage(.vietnamese)
    }
    
    // MARK: - Text Comparison Protocol Implementation
    func compareTexts(original: String, spoken: String) -> ComparisonResult {
        let normalizedOriginal = normalizeText(original)
        let normalizedSpoken = normalizeText(spoken)
        
        let mistakes = identifyMistakes(original: normalizedOriginal, spoken: normalizedSpoken)
        let accuracy = calculateAccuracy(original: normalizedOriginal, spoken: normalizedSpoken)
        let matchedWords = findMatchedWords(original: normalizedOriginal, spoken: normalizedSpoken)
        
        let result = ComparisonResult(
            originalText: original,
            spokenText: spoken,
            accuracy: accuracy,
            mistakes: mistakes,
            matchedWords: matchedWords,
            feedback: ""
        )
        
        let feedback = generateFeedback(comparisonResult: result)
        
        return ComparisonResult(
            originalText: original,
            spokenText: spoken,
            accuracy: accuracy,
            mistakes: mistakes,
            matchedWords: matchedWords,
            feedback: feedback
        )
    }
    
    func identifyMistakes(original: String, spoken: String) -> [TextMistake] {
        let originalWords = tokenizeText(original)
        let spokenWords = tokenizeText(spoken)
        
        return performDetailedComparison(originalWords: originalWords, spokenWords: spokenWords)
    }
    
    func calculateAccuracy(original: String, spoken: String) -> Float {
        let originalWords = tokenizeText(original)
        let spokenWords = tokenizeText(spoken)
        
        guard !originalWords.isEmpty else { return 1.0 }
        
        let mistakes = performDetailedComparison(originalWords: originalWords, spokenWords: spokenWords)
        let totalWords = originalWords.count
        let correctWords = max(0, totalWords - mistakes.count)
        
        return Float(correctWords) / Float(totalWords)
    }
    
    func generateFeedback(comparisonResult: ComparisonResult) -> String {
        return comparisonResult.performanceCategory.encouragementMessage + " " + comparisonResult.performanceCategory.emoji
    }
    
    // MARK: - Text Processing
    private func normalizeText(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // Remove extra whitespaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove punctuation for comparison
        let punctuation = CharacterSet.punctuationCharacters
        normalized = normalized.components(separatedBy: punctuation).joined()
        
        return normalized
    }
    
    private func tokenizeText(_ text: String) -> [String] {
        vietnameseTokenizer.string = text
        let tokens = vietnameseTokenizer.tokens(for: text.startIndex..<text.endIndex)
        
        return tokens.compactMap { range in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            return token.isEmpty ? nil : token
        }
    }
    
    // MARK: - Advanced Comparison
    private func performDetailedComparison(originalWords: [String], spokenWords: [String]) -> [TextMistake] {
        var mistakes: [TextMistake] = []
        
        // Use dynamic programming for optimal alignment
        let alignment = performSequenceAlignment(originalWords, spokenWords)
        
        for (index, operation) in alignment.enumerated() {
            switch operation {
            case .match:
                continue // No mistake
            case .substitution(let original, let spoken):
                let mistake = TextMistake(
                    position: index,
                    expectedWord: original,
                    actualWord: spoken,
                    mistakeType: determineMistakeType(expected: original, actual: spoken),
                    severity: calculateMistakeSeverity(expected: original, actual: spoken)
                )
                mistakes.append(mistake)
            case .deletion(let original):
                let mistake = TextMistake(
                    position: index,
                    expectedWord: original,
                    actualWord: "",
                    mistakeType: .omission,
                    severity: .moderate
                )
                mistakes.append(mistake)
            case .insertion(let spoken):
                let mistake = TextMistake(
                    position: index,
                    expectedWord: "",
                    actualWord: spoken,
                    mistakeType: .insertion,
                    severity: .minor
                )
                mistakes.append(mistake)
            }
        }
        
        return mistakes
    }
    
    private func performSequenceAlignment(_ seq1: [String], _ seq2: [String]) -> [AlignmentOperation] {
        let m = seq1.count
        let n = seq2.count
        
        // Dynamic programming matrix
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        // Initialize base cases
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...m {
            for j in 1...n {
                let cost = wordsAreSimilar(seq1[i-1], seq2[j-1]) ? 0 : 1
                dp[i][j] = min(
                    dp[i-1][j] + 1,      // deletion
                    dp[i][j-1] + 1,      // insertion
                    dp[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        // Backtrack to find alignment
        return backtrackAlignment(dp, seq1, seq2)
    }
    
    private func backtrackAlignment(_ dp: [[Int]], _ seq1: [String], _ seq2: [String]) -> [AlignmentOperation] {
        var operations: [AlignmentOperation] = []
        var i = seq1.count
        var j = seq2.count
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 {
                let cost = wordsAreSimilar(seq1[i-1], seq2[j-1]) ? 0 : 1
                if dp[i][j] == dp[i-1][j-1] + cost {
                    if cost == 0 {
                        operations.append(.match)
                    } else {
                        operations.append(.substitution(seq1[i-1], seq2[j-1]))
                    }
                    i -= 1
                    j -= 1
                    continue
                }
            }
            
            if i > 0 && dp[i][j] == dp[i-1][j] + 1 {
                operations.append(.deletion(seq1[i-1]))
                i -= 1
            } else if j > 0 && dp[i][j] == dp[i][j-1] + 1 {
                operations.append(.insertion(seq2[j-1]))
                j -= 1
            }
        }
        
        return operations.reversed()
    }
    
    // MARK: - Word Similarity
    private func wordsAreSimilar(_ word1: String, _ word2: String) -> Bool {
        // Exact match
        if word1 == word2 {
            return true
        }
        
        // Levenshtein distance check
        let distance = levenshteinDistance(word1, word2)
        if distance <= levenshteinThreshold {
            return true
        }
        
        // Phonetic similarity for Vietnamese
        if arePhoneticallySimilar(word1, word2) {
            return true
        }
        
        return false
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let a = Array(str1)
        let b = Array(str2)
        let m = a.count
        let n = b.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                dp[i][j] = min(
                    dp[i-1][j] + 1,
                    dp[i][j-1] + 1,
                    dp[i-1][j-1] + cost
                )
            }
        }
        
        return dp[m][n]
    }
    
    private func arePhoneticallySimilar(_ word1: String, _ word2: String) -> Bool {
        // Vietnamese phonetic similarity rules
        let phoneticPairs: [(String, String)] = [
            ("d", "gi"), ("gi", "d"),
            ("tr", "ch"), ("ch", "tr"),
            ("s", "x"), ("x", "s"),
            ("f", "ph"), ("ph", "f"),
            ("c", "k"), ("k", "c"),
            ("qu", "kw"), ("kw", "qu")
        ]
        
        for (sound1, sound2) in phoneticPairs {
            let variant1 = word1.replacingOccurrences(of: sound1, with: sound2)
            let variant2 = word2.replacingOccurrences(of: sound2, with: sound1)
            
            if variant1 == word2 || variant2 == word1 {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Mistake Analysis
    private func determineMistakeType(expected: String, actual: String) -> MistakeType {
        if arePhoneticallySimilar(expected, actual) {
            return .mispronunciation
        } else {
            return .substitution
        }
    }
    
    private func calculateMistakeSeverity(expected: String, actual: String) -> MistakeSeverity {
        let distance = levenshteinDistance(expected, actual)
        
        switch distance {
        case 0:
            return .minor // This shouldn't happen in mistakes, but just in case
        case 1:
            return .minor
        case 2:
            return .moderate
        default:
            return .major
        }
    }
    
    private func findMatchedWords(original: String, spoken: String) -> [String] {
        let originalWords = tokenizeText(original)
        let spokenWords = tokenizeText(spoken)
        
        var matchedWords: [String] = []
        
        for originalWord in originalWords {
            for spokenWord in spokenWords {
                if wordsAreSimilar(originalWord, spokenWord) {
                    matchedWords.append(originalWord)
                    break
                }
            }
        }
        
        return matchedWords
    }
}

// MARK: - Alignment Operation
private enum AlignmentOperation {
    case match
    case substitution(String, String)
    case deletion(String)
    case insertion(String)
}