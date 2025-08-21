import Foundation

// MARK: - Progress Tracking Usage Example
class ProgressTrackingExample {
    
    private let progressFactory = ProgressTrackingFactory.shared
    
    // MARK: - Example Usage Methods
    
    /// Example: Record a learning session and update progress
    func recordLearningSession() async {
        do {
            let userId = "student_123"
            let exerciseId = UUID()
            
            // Record a successful reading session
            try await progressFactory.recordSession(
                userId: userId,
                exerciseId: exerciseId,
                originalText: "Con mèo nhỏ ngồi trên thảm xanh. Nó có bộ lông mềm mại và đôi mắt sáng.",
                spokenText: "Con mèo nhỏ ngồi trên thảm xanh. Nó có bộ lông mềm mại và đôi mắt sáng.",
                accuracy: 0.95,
                score: 95,
                timeSpent: 180, // 3 minutes
                difficulty: .grade2,
                inputMethod: .voice,
                category: .reading
            )
            
            print("✅ Session recorded successfully!")
            
        } catch {
            print("❌ Error recording session: \(error)")
        }
    }
    
    /// Example: Get comprehensive progress summary
    func getProgressSummary() async {
        do {
            let userId = "student_123"
            let summary = try await progressFactory.getUserProgressSummary(userId: userId, period: .weekly)
            
            print("📊 Progress Summary for \(userId):")
            print("   • Total Sessions: \(summary.userProgress.totalSessions)")
            print("   • Average Accuracy: \(Int(summary.userProgress.averageAccuracy * 100))%")
            print("   • Current Streak: \(summary.streak.currentStreak) days")
            print("   • Health Score: \(summary.healthScore)/100")
            print("   • Performance: \(summary.userProgress.performanceLevel.localizedName)")
            
            if summary.isOnTrack {
                print("   • Status: ✅ On track with goals")
            } else {
                print("   • Status: ⚠️ Needs improvement")
            }
            
            if !summary.keyInsights.isEmpty {
                print("   • Key Insights:")
                for insight in summary.keyInsights {
                    print("     - \(insight)")
                }
            }
            
        } catch {
            print("❌ Error getting progress summary: \(error)")
        }
    }
    
    /// Example: Check daily goal completion
    func checkDailyGoals() async {
        do {
            let userId = "student_123"
            let goalStatus = try await progressFactory.checkDailyGoalCompletion(userId: userId)
            
            print("🎯 Daily Goal Status:")
            print("   • Goal Met: \(goalStatus.isGoalMet ? "✅ Yes" : "❌ No")")
            print("   • Progress: \(Int(goalStatus.progressPercentage * 100))%")
            print("   • Remaining Sessions: \(goalStatus.remainingSessions)")
            print("   • Remaining Time: \(goalStatus.formattedRemainingTime)")
            print("   • Message: \(goalStatus.motivationalMessage)")
            
        } catch {
            print("❌ Error checking daily goals: \(error)")
        }
    }
    
    /// Example: Update user learning goals
    func updateLearningGoals() async {
        do {
            let userId = "student_123"
            
            // Update goals to be more challenging
            try await progressFactory.updateUserGoals(
                userId: userId,
                dailySessionGoal: 5,        // 5 sessions per day
                dailyTimeGoal: 25 * 60,     // 25 minutes per day
                weeklySessionGoal: 30,      // 30 sessions per week
                accuracyGoal: 0.9,          // 90% accuracy target
                streakGoal: 14              // 2-week streak goal
            )
            
            print("✅ Learning goals updated successfully!")
            
        } catch {
            print("❌ Error updating learning goals: \(error)")
        }
    }
    
    /// Example: Get learning insights and recommendations
    func getLearningInsights() async {
        do {
            let userId = "student_123"
            let progressTracker = progressFactory.getProgressTracker()
            let insights = try await progressTracker.getLearningInsights(userId: userId)
            
            print("💡 Learning Insights:")
            
            if insights.isEmpty {
                print("   • No specific insights available yet. Keep learning!")
            } else {
                for insight in insights {
                    let priorityIcon = insight.priority == .high ? "🔴" : 
                                     insight.priority == .medium ? "🟡" : "🟢"
                    
                    print("   \(priorityIcon) \(insight.title)")
                    print("     Description: \(insight.description)")
                    print("     Recommendation: \(insight.recommendation)")
                    
                    if insight.actionable {
                        print("     Action Required: Yes")
                    }
                    print("")
                }
            }
            
        } catch {
            print("❌ Error getting learning insights: \(error)")
        }
    }
    
    /// Example: Compare progress with peers
    func compareWithPeers() async {
        do {
            let userId = "student_123"
            let progressTracker = progressFactory.getProgressTracker()
            let comparison = try await progressTracker.getProgressComparison(userId: userId, period: .monthly)
            
            print("👥 Peer Comparison:")
            print("   • Your Rank: #\(comparison.userRank) out of \(comparison.totalUsers)")
            print("   • Percentile: Top \(Int((1.0 - comparison.percentile) * 100))%")
            print("   • Your Accuracy: \(Int(comparison.userAccuracy * 100))%")
            print("   • Average Accuracy: \(Int(comparison.averageAccuracy * 100))%")
            print("   • Your Sessions/Week: \(Int(comparison.userSessionsPerWeek))")
            print("   • Average Sessions/Week: \(Int(comparison.averageSessionsPerWeek))")
            print("   • Your Streak: \(comparison.userStreak) days")
            print("   • Average Streak: \(comparison.averageStreak) days")
            
            print("   • Performance: \(comparison.relativePerformance.localizedName)")
            
            if !comparison.comparisonInsights.isEmpty {
                print("   • Insights:")
                for insight in comparison.comparisonInsights {
                    let icon = insight.isPositive ? "✅" : "⚠️"
                    print("     \(icon) \(insight.message)")
                    print("       Tip: \(insight.recommendation)")
                }
            }
            
        } catch {
            print("❌ Error comparing with peers: \(error)")
        }
    }
    
    /// Example: Export progress data
    func exportProgressData() async {
        do {
            let userId = "student_123"
            let progressTracker = progressFactory.getProgressTracker()
            
            // Export as JSON
            let jsonData = try await progressTracker.exportProgressData(userId: userId, format: .json)
            print("📄 JSON Export: \(jsonData.count) bytes")
            
            // Export as CSV
            let csvData = try await progressTracker.exportProgressData(userId: userId, format: .csv)
            print("📊 CSV Export: \(csvData.count) bytes")
            
            // You could save these to files or share them
            if let csvString = String(data: csvData, encoding: .utf8) {
                print("CSV Preview:")
                print(String(csvString.prefix(200)) + "...")
            }
            
        } catch {
            print("❌ Error exporting progress data: \(error)")
        }
    }
    
    /// Example: Simulate a week of learning sessions
    func simulateWeekOfLearning() async {
        print("🎓 Simulating a week of learning sessions...")
        
        let userId = "student_demo"
        let exercises = [
            ("Con chó nhỏ chạy quanh sân", DifficultyLevel.grade1),
            ("Mùa xuân đến, hoa nở khắp nơi", DifficultyLevel.grade2),
            ("Gia đình tôi đi picnic cuối tuần", DifficultyLevel.grade2),
            ("Bảo vệ môi trường là trách nhiệm của chúng ta", DifficultyLevel.grade3),
            ("Khoa học giúp chúng ta hiểu về thế giới", DifficultyLevel.grade3)
        ]
        
        for day in 1...7 {
            for session in 1...3 {
                let exercise = exercises.randomElement()!
                let accuracy = Float.random(in: 0.75...1.0)
                let timeSpent = TimeInterval.random(in: 60...300) // 1-5 minutes
                
                do {
                    try await progressFactory.recordSession(
                        userId: userId,
                        exerciseId: UUID(),
                        originalText: exercise.0,
                        spokenText: exercise.0, // Assume perfect speech recognition for demo
                        accuracy: accuracy,
                        score: Int(accuracy * 100),
                        timeSpent: timeSpent,
                        difficulty: exercise.1,
                        inputMethod: [.keyboard, .voice, .handwriting].randomElement()!,
                        category: .reading
                    )
                    
                    print("   Day \(day), Session \(session): \(Int(accuracy * 100))% accuracy")
                    
                } catch {
                    print("   ❌ Error in Day \(day), Session \(session): \(error)")
                }
            }
        }
        
        // Show final summary
        await getProgressSummary()
    }
    
    /// Run all examples
    func runAllExamples() async {
        print("🚀 Running Progress Tracking Examples\n")
        
        await recordLearningSession()
        print("")
        
        await updateLearningGoals()
        print("")
        
        await checkDailyGoals()
        print("")
        
        await getProgressSummary()
        print("")
        
        await getLearningInsights()
        print("")
        
        await compareWithPeers()
        print("")
        
        await exportProgressData()
        print("")
        
        print("✨ All examples completed!")
    }
}

// MARK: - Usage
/*
 To use this example:
 
 let example = ProgressTrackingExample()
 
 // Run individual examples
 await example.recordLearningSession()
 await example.getProgressSummary()
 await example.checkDailyGoals()
 
 // Or run all examples
 await example.runAllExamples()
 
 // Simulate a full week of learning
 await example.simulateWeekOfLearning()
 */