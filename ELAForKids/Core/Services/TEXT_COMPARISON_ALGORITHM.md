# Text Comparison Algorithm Documentation

## Overview

The Text Comparison Algorithm is a sophisticated system designed to compare original Vietnamese text with spoken text (converted from speech recognition) and provide detailed analysis of reading accuracy. It's specifically optimized for Vietnamese language characteristics and educational use cases for elementary school children.

## Key Features

### 1. Advanced Text Alignment
- Uses dynamic programming (Wagner-Fischer algorithm) for optimal sequence alignment
- Handles insertions, deletions, substitutions, and matches
- Provides accurate word-by-word comparison even with significant differences

### 2. Vietnamese Language Support
- Vietnamese-specific tokenization using NaturalLanguage framework
- Phonetic similarity detection for common Vietnamese pronunciation patterns
- Handles Vietnamese diacritics and tone marks appropriately

### 3. Intelligent Mistake Classification
- **Mispronunciation**: Phonetically similar words (e.g., "chạy" vs "trạy")
- **Omission**: Missing words from the original text
- **Insertion**: Extra words not in the original text
- **Substitution**: Completely different words

### 4. Severity Assessment
- **Minor**: Small differences (Levenshtein distance = 1)
- **Moderate**: Medium differences (Levenshtein distance = 2)
- **Major**: Large differences (Levenshtein distance > 2)

### 5. Performance Categories
- **Excellent**: 95-100% accuracy
- **Good**: 85-94% accuracy
- **Fair**: 70-84% accuracy
- **Needs Improvement**: <70% accuracy

## Algorithm Components

### Text Normalization
```swift
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
```

### Vietnamese Tokenization
- Uses `NLTokenizer` with Vietnamese language setting
- Properly handles Vietnamese word boundaries
- Filters out empty tokens and whitespace

### Sequence Alignment Algorithm
The core comparison uses a dynamic programming approach:

1. **Initialization**: Create a matrix where `dp[i][j]` represents the minimum edit distance between the first `i` words of the original text and the first `j` words of the spoken text.

2. **Matrix Filling**: For each cell, calculate the minimum cost of:
   - Deletion: `dp[i-1][j] + 1`
   - Insertion: `dp[i][j-1] + 1`
   - Substitution/Match: `dp[i-1][j-1] + cost` (cost = 0 for similar words, 1 for different)

3. **Backtracking**: Trace back through the matrix to determine the optimal alignment operations.

### Word Similarity Detection
Words are considered similar if they meet any of these criteria:

1. **Exact Match**: Identical after normalization
2. **Levenshtein Distance**: Edit distance ≤ 2
3. **Phonetic Similarity**: Vietnamese-specific phonetic patterns

### Vietnamese Phonetic Patterns
The algorithm recognizes common Vietnamese pronunciation confusions:
- `d` ↔ `gi`
- `tr` ↔ `ch`
- `s` ↔ `x`
- `f` ↔ `ph`
- `c` ↔ `k`
- `qu` ↔ `kw`

## Usage Examples

### Basic Comparison
```swift
let textComparator = TextComparisonEngine()
let result = textComparator.compareTexts(
    original: "Con mèo ngồi trên thảm",
    spoken: "Con mèo ngồi trên ghế"
)

print("Accuracy: \(result.accuracy)")
print("Mistakes: \(result.mistakes.count)")
print("Feedback: \(result.feedback)")
```

### Detailed Mistake Analysis
```swift
for mistake in result.mistakes {
    print("Position: \(mistake.position)")
    print("Expected: '\(mistake.expectedWord)'")
    print("Actual: '\(mistake.actualWord)'")
    print("Type: \(mistake.mistakeType)")
    print("Severity: \(mistake.severity)")
    print("Description: \(mistake.description)")
    print("Suggestion: \(mistake.suggestion)")
}
```

## Performance Characteristics

### Time Complexity
- **Best Case**: O(m + n) for identical texts
- **Average Case**: O(m × n) where m and n are the number of words
- **Worst Case**: O(m × n) for completely different texts

### Space Complexity
- O(m × n) for the dynamic programming matrix
- Additional O(m + n) for storing alignment operations

### Optimization Strategies
1. **Early Termination**: Stop processing if texts are identical after normalization
2. **Similarity Caching**: Cache word similarity calculations
3. **Tokenization Optimization**: Reuse tokenizer instances
4. **Memory Management**: Use efficient data structures for large texts

## Testing Strategy

### Unit Tests
- Perfect matches (100% accuracy)
- Single word substitutions
- Multiple word substitutions
- Word omissions and insertions
- Vietnamese phonetic similarities
- Edge cases (empty strings, punctuation)
- Performance tests with long texts

### Test Cases Coverage
- **Exact Matches**: Various text lengths and complexities
- **Substitutions**: Single and multiple word replacements
- **Omissions**: Missing words at different positions
- **Insertions**: Extra words at different positions
- **Phonetic Similarities**: Vietnamese-specific pronunciation patterns
- **Mixed Mistakes**: Combinations of different mistake types
- **Edge Cases**: Empty strings, punctuation, special characters
- **Performance**: Long texts, many mistakes

## Error Handling

### Graceful Degradation
- Empty input strings return 100% accuracy
- Invalid characters are filtered during normalization
- Tokenization failures fall back to simple word splitting
- Memory constraints are handled with appropriate limits

### Validation
- Input text length limits to prevent memory issues
- Character encoding validation for Vietnamese text
- Null and empty string handling

## Integration Points

### Speech Recognition Integration
```swift
// After speech recognition completes
let recognizedText = speechRecognizer.getRecognizedText()
let comparisonResult = textComparator.compareTexts(
    original: originalText,
    spoken: recognizedText
)
```

### UI Feedback Integration
```swift
// Display results in UI
accuracyLabel.text = "\(Int(result.accuracy * 100))%"
feedbackLabel.text = result.feedback
performanceIcon.image = UIImage(named: result.performanceCategory.emoji)

// Highlight mistakes in text
for mistake in result.mistakes {
    highlightWord(at: mistake.position, type: mistake.mistakeType)
}
```

### Scoring System Integration
```swift
// Calculate score based on accuracy and attempts
let score = scoreCalculator.calculateScore(
    accuracy: result.accuracy,
    attempts: attemptCount,
    difficulty: exerciseDifficulty
)
```

## Future Enhancements

### Planned Improvements
1. **Machine Learning Integration**: Use ML models for better phonetic similarity detection
2. **Context Awareness**: Consider sentence context for better mistake classification
3. **Adaptive Thresholds**: Adjust similarity thresholds based on user proficiency level
4. **Regional Accent Support**: Handle different Vietnamese regional pronunciations
5. **Real-time Processing**: Optimize for real-time speech comparison
6. **Confidence Scoring**: Provide confidence levels for mistake detection

### Performance Optimizations
1. **Parallel Processing**: Use concurrent queues for large text processing
2. **Caching**: Implement intelligent caching for repeated comparisons
3. **Memory Optimization**: Reduce memory footprint for mobile devices
4. **Algorithm Improvements**: Explore more efficient alignment algorithms

## Configuration Options

### Adjustable Parameters
```swift
// Similarity thresholds
private let minimumWordSimilarity: Float = 0.7
private let levenshteinThreshold: Int = 2

// Performance categories
private let excellentThreshold: Float = 0.95
private let goodThreshold: Float = 0.85
private let fairThreshold: Float = 0.70
```

### Language Settings
```swift
// Vietnamese language configuration
vietnameseTokenizer.setLanguage(.vietnamese)

// Custom phonetic patterns
let customPhoneticPairs: [(String, String)] = [
    ("custom1", "custom2"),
    // Add more patterns as needed
]
```

## Troubleshooting

### Common Issues
1. **Low Accuracy for Correct Reading**: Check phonetic similarity patterns
2. **High Processing Time**: Optimize text length or use background processing
3. **Incorrect Tokenization**: Verify Vietnamese language setting
4. **Memory Issues**: Implement text length limits

### Debug Information
```swift
// Enable detailed logging
let result = textComparator.compareTexts(original: original, spoken: spoken)
print("Original words: \(textComparator.tokenizeText(original))")
print("Spoken words: \(textComparator.tokenizeText(spoken))")
print("Alignment operations: \(alignmentOperations)")
```

## Conclusion

The Text Comparison Algorithm provides a robust, accurate, and educationally-focused solution for comparing Vietnamese text with spoken input. Its sophisticated approach to handling Vietnamese language characteristics, combined with detailed mistake analysis and user-friendly feedback, makes it ideal for educational applications targeting elementary school children.

The algorithm balances accuracy with performance, providing real-time feedback while maintaining high precision in mistake detection and classification. Its modular design allows for easy integration with other system components and future enhancements.