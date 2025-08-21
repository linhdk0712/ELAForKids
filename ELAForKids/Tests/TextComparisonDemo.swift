import Foundation

// Simple demo script to test the text comparison algorithm
class TextComparisonDemo {
    private let textComparator = TextComparisonEngine()
    
    func runDemo() {
        print("🎯 Text Comparison Algorithm Demo")
        print("==================================\n")
        
        // Test cases
        let testCases: [(String, String, String)] = [
            ("Con mèo ngồi trên thảm", "Con mèo ngồi trên thảm", "Perfect Match"),
            ("Con mèo ngồi trên thảm", "Con mèo ngồi trên ghế", "Single Substitution"),
            ("Con mèo ngồi trên thảm", "Con mèo trên thảm", "Word Omission"),
            ("Con mèo ngồi trên thảm", "Con mèo nhỏ ngồi trên thảm", "Word Insertion"),
            ("Con mèo ngồi trên thảm", "Con chó đứng trên ghế", "Multiple Substitutions"),
            ("Con dê đang ăn", "Con giê đang ăn", "Vietnamese Phonetic (d/gi)"),
            ("Con chó đang chạy", "Con chó đang trạy", "Vietnamese Phonetic (ch/tr)"),
            ("", "", "Empty Strings"),
            ("Con mèo", "", "Complete Omission"),
            ("", "Con mèo", "Complete Insertion")
        ]
        
        for (index, (original, spoken, description)) in testCases.enumerated() {
            print("Test \(index + 1): \(description)")
            print("Original: '\(original)'")
            print("Spoken:   '\(spoken)'")
            
            let result = textComparator.compareTexts(original: original, spoken: spoken)
            
            print("Accuracy: \(String(format: "%.1f", result.accuracy * 100))%")
            print("Performance: \(result.performanceCategory.localizedName) \(result.performanceCategory.emoji)")
            print("Mistakes: \(result.mistakes.count)")
            
            if !result.mistakes.isEmpty {
                print("Mistake Details:")
                for mistake in result.mistakes {
                    print("  - \(mistake.description) (\(mistake.mistakeType.localizedName), \(mistake.severity.localizedName))")
                }
            }
            
            print("Feedback: \(result.feedback)")
            print("Matched Words: \(result.matchedWords.joined(separator: ", "))")
            print("---")
        }
        
        // Performance test
        print("\n⚡ Performance Test")
        print("==================")
        
        let longOriginal = String(repeating: "Con mèo ngồi trên thảm xanh trong phòng khách. ", count: 50)
        let longSpoken = String(repeating: "Con mèo ngồi trên thảm đỏ trong phòng khách. ", count: 50)
        
        let startTime = Date()
        let result = textComparator.compareTexts(original: longOriginal, spoken: longSpoken)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        
        print("Long text comparison (\(result.totalWords) words)")
        print("Execution time: \(String(format: "%.3f", executionTime)) seconds")
        print("Accuracy: \(String(format: "%.1f", result.accuracy * 100))%")
        print("Mistakes: \(result.mistakes.count)")
        
        print("\n✅ Demo completed successfully!")
    }
}

// Run the demo
let demo = TextComparisonDemo()
demo.runDemo()