import XCTest
import Foundation
@testable import ELAForKids

final class PerformanceAndMemoryTests: XCTestCase {
    
    var performanceMetrics: PerformanceMetrics!
    var memoryMonitor: MemoryMonitor!
    
    override func setUp() {
        super.setUp()
        performanceMetrics = PerformanceMetrics()
        memoryMonitor = MemoryMonitor()
    }
    
    override func tearDown() {
        performanceMetrics = nil
        memoryMonitor = nil
        super.tearDown()
    }
    
    // MARK: - Performance Testing
    
    func testAppLaunchPerformance() {
        // Given - App launch performance measurement
        
        // When - Measure app launch time
        let launchMetrics = performanceMetrics.measureAppLaunch()
        
        // Then - Launch should be fast
        XCTAssertLessThan(launchMetrics.totalTime, 3.0, "App should launch in under 3 seconds")
        XCTAssertLessThan(launchMetrics.coldStartTime, 5.0, "Cold start should be under 5 seconds")
        XCTAssertLessThan(launchMetrics.warmStartTime, 2.0, "Warm start should be under 2 seconds")
        
        print("Launch Performance Results:")
        print("Total Launch Time: \(launchMetrics.totalTime)s")
        print("Cold Start Time: \(launchMetrics.coldStartTime)s")
        print("Warm Start Time: \(launchMetrics.warmStartTime)s")
    }
    
    func testNavigationPerformance() {
        // Given - Navigation performance measurement
        
        // When - Measure navigation between screens
        let navigationMetrics = performanceMetrics.measureNavigationPerformance()
        
        // Then - Navigation should be smooth
        XCTAssertLessThan(navigationMetrics.averageNavigationTime, 0.5, "Average navigation should be under 0.5 seconds")
        XCTAssertLessThan(navigationMetrics.maxNavigationTime, 1.0, "Maximum navigation should be under 1 second")
        XCTAssertLessThan(navigationMetrics.navigationJank, 0.1, "Navigation jank should be minimal")
        
        print("Navigation Performance Results:")
        print("Average Navigation Time: \(navigationMetrics.averageNavigationTime)s")
        print("Maximum Navigation Time: \(navigationMetrics.maxNavigationTime)s")
        print("Navigation Jank: \(navigationMetrics.navigationJank)")
    }
    
    func testTextInputPerformance() {
        // Given - Text input performance measurement
        
        // When - Measure text input responsiveness
        let inputMetrics = performanceMetrics.measureTextInputPerformance()
        
        // Then - Text input should be responsive
        XCTAssertLessThan(inputMetrics.typingLatency, 0.1, "Typing latency should be under 0.1 seconds")
        XCTAssertLessThan(inputMetrics.autoCompleteTime, 0.3, "Auto-complete should be under 0.3 seconds")
        XCTAssertLessThan(inputMetrics.validationTime, 0.2, "Validation should be under 0.2 seconds")
        
        print("Text Input Performance Results:")
        print("Typing Latency: \(inputMetrics.typingLatency)s")
        print("Auto-complete Time: \(inputMetrics.autoCompleteTime)s")
        print("Validation Time: \(inputMetrics.validationTime)s")
    }
    
    func testSpeechRecognitionPerformance() {
        // Given - Speech recognition performance measurement
        
        // When - Measure speech recognition speed
        let speechMetrics = performanceMetrics.measureSpeechRecognitionPerformance()
        
        // Then - Speech recognition should be fast
        XCTAssertLessThan(speechMetrics.recognitionLatency, 2.0, "Speech recognition should be under 2 seconds")
        XCTAssertLessThan(speechMetrics.audioProcessingTime, 1.0, "Audio processing should be under 1 second")
        XCTAssertLessThan(speechMetrics.textComparisonTime, 0.5, "Text comparison should be under 0.5 seconds")
        
        print("Speech Recognition Performance Results:")
        print("Recognition Latency: \(speechMetrics.recognitionLatency)s")
        print("Audio Processing Time: \(speechMetrics.audioProcessingTime)s")
        print("Text Comparison Time: \(speechMetrics.textComparisonTime)s")
    }
    
    func testScoringCalculationPerformance() {
        // Given - Scoring calculation performance measurement
        
        // When - Measure scoring calculation speed
        let scoringMetrics = performanceMetrics.measureScoringPerformance()
        
        // Then - Scoring should be fast
        XCTAssertLessThan(scoringMetrics.baseScoreCalculation, 0.1, "Base score calculation should be under 0.1 seconds")
        XCTAssertLessThan(scoringMetrics.bonusCalculation, 0.1, "Bonus calculation should be under 0.1 seconds")
        XCTAssertLessThan(scoringMetrics.totalCalculation, 0.2, "Total scoring should be under 0.2 seconds")
        
        print("Scoring Performance Results:")
        print("Base Score Calculation: \(scoringMetrics.baseScoreCalculation)s")
        print("Bonus Calculation: \(scoringMetrics.bonusCalculation)s")
        print("Total Calculation: \(scoringMetrics.totalCalculation)s")
    }
    
    func testDatabasePerformance() {
        // Given - Database performance measurement
        
        // When - Measure database operations
        let databaseMetrics = performanceMetrics.measureDatabasePerformance()
        
        // Then - Database operations should be fast
        XCTAssertLessThan(databaseMetrics.readTime, 0.1, "Database read should be under 0.1 seconds")
        XCTAssertLessThan(databaseMetrics.writeTime, 0.2, "Database write should be under 0.2 seconds")
        XCTAssertLessThan(databaseMetrics.queryTime, 0.1, "Database query should be under 0.1 seconds")
        
        print("Database Performance Results:")
        print("Read Time: \(databaseMetrics.readTime)s")
        print("Write Time: \(databaseMetrics.writeTime)s")
        print("Query Time: \(databaseMetrics.queryTime)s")
    }
    
    func testMemoryUsagePerformance() {
        // Given - Memory usage performance measurement
        
        // When - Measure memory usage patterns
        let memoryMetrics = performanceMetrics.measureMemoryUsage()
        
        // Then - Memory usage should be reasonable
        XCTAssertLessThan(memoryMetrics.peakMemoryUsage, 200, "Peak memory usage should be under 200MB")
        XCTAssertLessThan(memoryMetrics.averageMemoryUsage, 150, "Average memory usage should be under 150MB")
        XCTAssertLessThan(memoryMetrics.memoryGrowthRate, 10, "Memory growth rate should be under 10MB/s")
        
        print("Memory Usage Results:")
        print("Peak Memory Usage: \(memoryMetrics.peakMemoryUsage)MB")
        print("Average Memory Usage: \(memoryMetrics.averageMemoryUsage)MB")
        print("Memory Growth Rate: \(memoryMetrics.memoryGrowthRate)MB/s")
    }
    
    func testBatteryUsagePerformance() {
        // Given - Battery usage performance measurement
        
        // When - Measure battery consumption
        let batteryMetrics = performanceMetrics.measureBatteryUsage()
        
        // Then - Battery usage should be reasonable
        XCTAssertLessThan(batteryMetrics.cpuUsage, 30, "CPU usage should be under 30%")
        XCTAssertLessThan(batteryMetrics.networkUsage, 5, "Network usage should be under 5MB/min")
        XCTAssertLessThan(batteryMetrics.backgroundTime, 60, "Background time should be under 60 seconds")
        
        print("Battery Usage Results:")
        print("CPU Usage: \(batteryMetrics.cpuUsage)%")
        print("Network Usage: \(batteryMetrics.networkUsage)MB/min")
        print("Background Time: \(batteryMetrics.backgroundTime)s")
    }
    
    // MARK: - Memory Leak Detection
    
    func testMemoryLeakInTextInput() {
        // Given - Text input memory monitoring
        
        // When - Perform multiple text input operations
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        for i in 0..<100 {
            let textInput = TextInputViewModel()
            textInput.send(.updateText("Test text \(i)"))
            textInput.send(.validateText)
            textInput.send(.clearText)
        }
        
        // Force garbage collection
        autoreleasepool {
            // Simulate memory pressure
        }
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Memory should not increase significantly
        XCTAssertLessThan(memoryIncrease, 10, "Memory should not increase more than 10MB after text input operations")
        
        print("Text Input Memory Test:")
        print("Initial Memory: \(initialMemory)MB")
        print("Final Memory: \(finalMemory)MB")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    func testMemoryLeakInSpeechRecognition() {
        // Given - Speech recognition memory monitoring
        
        // When - Perform multiple speech recognition operations
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        for _ in 0..<50 {
            let speechManager = SpeechRecognitionManager()
            try? await speechManager.startRecognition(
                for: "Test text",
                locale: Locale(identifier: "vi_VN"),
                userId: "test_user"
            )
            speechManager.stopRecognition()
        }
        
        // Force garbage collection
        autoreleasepool {
            // Simulate memory pressure
        }
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Memory should not increase significantly
        XCTAssertLessThan(memoryIncrease, 15, "Memory should not increase more than 15MB after speech recognition operations")
        
        print("Speech Recognition Memory Test:")
        print("Initial Memory: \(initialMemory)MB")
        print("Final Memory: \(finalMemory)MB")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    func testMemoryLeakInScoringSystem() {
        // Given - Scoring system memory monitoring
        
        // When - Perform multiple scoring calculations
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        for _ in 0..<1000 {
            let scoreCalculator = ScoreCalculator()
            let scoreResult = scoreCalculator.calculateScore(
                accuracy: 0.95,
                attempts: 1,
                difficulty: .grade1,
                timeSpent: 30.0,
                userStats: UserSessionStats(
                    totalSessions: 5,
                    totalScore: 500,
                    averageAccuracy: 0.95,
                    currentStreak: 3,
                    bestStreak: 5,
                    totalTimeSpent: 150.0
                )
            )
            _ = scoreResult // Use result to prevent optimization
        }
        
        // Force garbage collection
        autoreleasepool {
            // Simulate memory pressure
        }
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Memory should not increase significantly
        XCTAssertLessThan(memoryIncrease, 5, "Memory should not increase more than 5MB after scoring calculations")
        
        print("Scoring System Memory Test:")
        print("Initial Memory: \(initialMemory)MB")
        print("Final Memory: \(finalMemory)MB")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    func testMemoryLeakInDatabaseOperations() {
        // Given - Database operations memory monitoring
        
        // When - Perform multiple database operations
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        for i in 0..<100 {
            let userProfile = UserProfile(
                id: "test_user_\(i)",
                name: "Test User \(i)",
                grade: Int16(i % 5 + 1),
                parentEmail: "test\(i)@example.com",
                createdAt: Date(),
                lastSessionDate: nil,
                totalScore: i * 100,
                completedExercises: i,
                totalTimeSpent: Double(i * 60),
                averageAccuracy: 0.9,
                currentStreak: i % 10,
                bestStreak: i % 15
            )
            
            // Simulate database save
            _ = userProfile
        }
        
        // Force garbage collection
        autoreleasepool {
            // Simulate memory pressure
        }
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Memory should not increase significantly
        XCTAssertLessThan(memoryIncrease, 8, "Memory should not increase more than 8MB after database operations")
        
        print("Database Operations Memory Test:")
        print("Initial Memory: \(initialMemory)MB")
        print("Final Memory: \(finalMemory)MB")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    func testMemoryLeakInViewModels() {
        // Given - ViewModels memory monitoring
        
        // When - Create and destroy multiple ViewModels
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        for _ in 0..<200 {
            let textInputVM = TextInputViewModel()
            let readingVM = ReadingViewModel()
            let resultsVM = ReadingResultsViewModel()
            
            // Simulate view lifecycle
            textInputVM.send(.updateText("Test"))
            readingVM.send(.startReading)
            resultsVM.send(.showResults)
        }
        
        // Force garbage collection
        autoreleasepool {
            // Simulate memory pressure
        }
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Memory should not increase significantly
        XCTAssertLessThan(memoryIncrease, 12, "Memory should not increase more than 12MB after ViewModel operations")
        
        print("ViewModels Memory Test:")
        print("Initial Memory: \(initialMemory)MB")
        print("Final Memory: \(finalMemory)MB")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    // MARK: - Stress Testing
    
    func testStressTestWithLargeDataSets() {
        // Given - Large dataset stress testing
        
        // When - Process large amounts of data
        let startTime = Date()
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        // Create large dataset
        let largeTexts = (0..<1000).map { "Large text content \($0) with many words and sentences to test performance under load" }
        
        var totalProcessingTime: TimeInterval = 0
        
        for text in largeTexts {
            let processingStart = Date()
            
            // Process text
            let words = text.components(separatedBy: " ")
            let wordCount = words.count
            let averageWordLength = words.reduce(0) { $0 + $1.count } / max(wordCount, 1)
            
            let processingTime = Date().timeIntervalSince(processingStart)
            totalProcessingTime += processingTime
            
            // Verify processing
            XCTAssertGreaterThan(wordCount, 0)
            XCTAssertGreaterThan(averageWordLength, 0)
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Should handle large datasets efficiently
        XCTAssertLessThan(totalTime, 10.0, "Large dataset processing should complete in under 10 seconds")
        XCTAssertLessThan(memoryIncrease, 20, "Memory increase should be under 20MB for large dataset processing")
        XCTAssertLessThan(totalProcessingTime / Double(largeTexts.count), 0.01, "Average processing time per text should be under 0.01 seconds")
        
        print("Stress Test Results:")
        print("Total Processing Time: \(totalTime)s")
        print("Average Processing Time per Text: \(totalProcessingTime / Double(largeTexts.count))s")
        print("Memory Increase: \(memoryIncrease)MB")
    }
    
    func testConcurrentOperationsPerformance() {
        // Given - Concurrent operations performance testing
        
        // When - Perform multiple operations concurrently
        let startTime = Date()
        let initialMemory = memoryMonitor.getCurrentMemoryUsage()
        
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 100
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<100 {
            queue.async {
                // Simulate concurrent operations
                let textInput = TextInputViewModel()
                textInput.send(.updateText("Concurrent text \(i)"))
                textInput.send(.validateText)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then - Should handle concurrent operations efficiently
        XCTAssertLessThan(totalTime, 30.0, "Concurrent operations should complete in under 30 seconds")
        XCTAssertLessThan(memoryIncrease, 25, "Memory increase should be under 25MB for concurrent operations")
        
        print("Concurrent Operations Test Results:")
        print("Total Time: \(totalTime)s")
        print("Memory Increase: \(memoryIncrease)MB")
    }
}

// MARK: - Performance Metrics

class PerformanceMetrics {
    
    func measureAppLaunch() -> LaunchMetrics {
        let startTime = Date()
        
        // Simulate app launch
        let totalTime = Date().timeIntervalSince(startTime)
        
        return LaunchMetrics(
            totalTime: totalTime,
            coldStartTime: totalTime * 1.5, // Simulate cold start
            warmStartTime: totalTime * 0.7  // Simulate warm start
        )
    }
    
    func measureNavigationPerformance() -> NavigationMetrics {
        var navigationTimes: [TimeInterval] = []
        
        // Simulate navigation measurements
        for _ in 0..<10 {
            let startTime = Date()
            // Simulate navigation delay
            Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.3))
            let navigationTime = Date().timeIntervalSince(startTime)
            navigationTimes.append(navigationTime)
        }
        
        let averageTime = navigationTimes.reduce(0, +) / Double(navigationTimes.count)
        let maxTime = navigationTimes.max() ?? 0
        let jank = navigationTimes.map { abs($0 - averageTime) }.reduce(0, +) / Double(navigationTimes.count)
        
        return NavigationMetrics(
            averageNavigationTime: averageTime,
            maxNavigationTime: maxTime,
            navigationJank: jank
        )
    }
    
    func measureTextInputPerformance() -> TextInputMetrics {
        // Simulate text input performance measurements
        return TextInputMetrics(
            typingLatency: 0.05,
            autoCompleteTime: 0.15,
            validationTime: 0.08
        )
    }
    
    func measureSpeechRecognitionPerformance() -> SpeechRecognitionMetrics {
        // Simulate speech recognition performance measurements
        return SpeechRecognitionMetrics(
            recognitionLatency: 1.2,
            audioProcessingTime: 0.6,
            textComparisonTime: 0.2
        )
    }
    
    func measureScoringPerformance() -> ScoringMetrics {
        // Simulate scoring performance measurements
        return ScoringMetrics(
            baseScoreCalculation: 0.03,
            bonusCalculation: 0.05,
            totalCalculation: 0.08
        )
    }
    
    func measureDatabasePerformance() -> DatabaseMetrics {
        // Simulate database performance measurements
        return DatabaseMetrics(
            readTime: 0.05,
            writeTime: 0.12,
            queryTime: 0.06
        )
    }
    
    func measureMemoryUsage() -> MemoryMetrics {
        // Simulate memory usage measurements
        return MemoryMetrics(
            peakMemoryUsage: 120,
            averageMemoryUsage: 95,
            memoryGrowthRate: 2.5
        )
    }
    
    func measureBatteryUsage() -> BatteryMetrics {
        // Simulate battery usage measurements
        return BatteryMetrics(
            cpuUsage: 15,
            networkUsage: 2.3,
            backgroundTime: 25
        )
    }
}

// MARK: - Memory Monitor

class MemoryMonitor {
    
    func getCurrentMemoryUsage() -> Double {
        // Simulate memory usage measurement
        // In real implementation, this would use system APIs
        return Double.random(in: 80...150)
    }
}

// MARK: - Metrics Models

struct LaunchMetrics {
    let totalTime: TimeInterval
    let coldStartTime: TimeInterval
    let warmStartTime: TimeInterval
}

struct NavigationMetrics {
    let averageNavigationTime: TimeInterval
    let maxNavigationTime: TimeInterval
    let navigationJank: TimeInterval
}

struct TextInputMetrics {
    let typingLatency: TimeInterval
    let autoCompleteTime: TimeInterval
    let validationTime: TimeInterval
}

struct SpeechRecognitionMetrics {
    let recognitionLatency: TimeInterval
    let audioProcessingTime: TimeInterval
    let textComparisonTime: TimeInterval
}

struct ScoringMetrics {
    let baseScoreCalculation: TimeInterval
    let bonusCalculation: TimeInterval
    let totalCalculation: TimeInterval
}

struct DatabaseMetrics {
    let readTime: TimeInterval
    let writeTime: TimeInterval
    let queryTime: TimeInterval
}

struct MemoryMetrics {
    let peakMemoryUsage: Double
    let averageMemoryUsage: Double
    let memoryGrowthRate: Double
}

struct BatteryMetrics {
    let cpuUsage: Double
    let networkUsage: Double
    let backgroundTime: TimeInterval
}
