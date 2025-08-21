import SwiftUI

// MARK: - Practice Tab View
struct PracticeTabView: View {
    @ObservedObject var viewModel: MainMenuViewModel
    @State private var selectedDifficulty: DifficultyLevel = .grade2
    @State private var selectedCategory: ExerciseCategory = .story
    @State private var showingPracticeSession = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header section
                headerSection
                
                // Difficulty selection
                difficultySelectionSection
                
                // Category selection
                categorySelectionSection
                
                // Recommended exercises
                recommendedExercisesSection
                
                // Recent exercises
                recentExercisesSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Luyện tập đọc")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Chọn bài học phù hợp với bé")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick start button
            Button(action: {
                startQuickPractice()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.headline)
                    
                    Text("Bắt đầu ngay")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Difficulty Selection Section
    
    @ViewBuilder
    private var difficultySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chọn cấp độ")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        difficultyCard(difficulty)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private func difficultyCard(_ difficulty: DifficultyLevel) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDifficulty = difficulty
            }
        }) {
            VStack(spacing: 8) {
                Text(difficulty.emoji)
                    .font(.system(size: 32))
                
                Text(difficulty.localizedName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                
                Text("Độ chính xác: \(Int(difficulty.expectedAccuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(selectedDifficulty == difficulty ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 120, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedDifficulty == difficulty ? difficulty.color : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category Selection Section
    
    @ViewBuilder
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chọn thể loại")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryCard(_ category: ExerciseCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(selectedCategory == category ? .white : category.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(selectedCategory == category ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedCategory == category ? category.color : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Recommended Exercises Section
    
    @ViewBuilder
    private var recommendedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bài học đề xuất")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Dành cho \(selectedDifficulty.localizedName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(getRecommendedExercises(), id: \.id) { exercise in
                    exerciseCard(exercise, isRecommended: true)
                }
            }
        }
    }
    
    // MARK: - Recent Exercises Section
    
    @ViewBuilder
    private var recentExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bài học gần đây")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(getRecentExercises(), id: \.id) { exercise in
                    exerciseCard(exercise, isRecommended: false)
                }
            }
        }
    }
    
    // MARK: - Exercise Card
    
    @ViewBuilder
    private func exerciseCard(_ exercise: ExerciseInfo, isRecommended: Bool) -> some View {
        Button(action: {
            startExercise(exercise)
        }) {
            HStack(spacing: 16) {
                // Exercise icon
                VStack {
                    Image(systemName: exercise.category.icon)
                        .font(.title2)
                        .foregroundColor(exercise.category.color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(exercise.category.color.opacity(0.1))
                        )
                    
                    if isRecommended {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                // Exercise details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(exercise.preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(exercise.difficulty.localizedName, systemImage: "graduationcap.fill")
                            .font(.caption)
                            .foregroundColor(exercise.difficulty.color)
                        
                        Label("\(exercise.estimatedTime) phút", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let accuracy = exercise.lastAccuracy {
                            Label("\(Int(accuracy * 100))%", systemImage: "target")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Action button
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func startQuickPractice() {
        viewModel.startPracticeSession(difficulty: selectedDifficulty)
    }
    
    private func startExercise(_ exercise: ExerciseInfo) {
        // This would navigate to the specific exercise
        print("Starting exercise: \(exercise.title)")
    }
    
    private func getRecommendedExercises() -> [ExerciseInfo] {
        // This would fetch recommended exercises based on user progress
        return [
            ExerciseInfo(
                id: "rec_1",
                title: "Con mèo nhỏ",
                preview: "Con mèo nhỏ màu nâu chạy quanh sân...",
                category: selectedCategory,
                difficulty: selectedDifficulty,
                estimatedTime: 3,
                lastAccuracy: nil
            ),
            ExerciseInfo(
                id: "rec_2",
                title: "Gia đình tôi",
                preview: "Gia đình tôi có bốn người...",
                category: selectedCategory,
                difficulty: selectedDifficulty,
                estimatedTime: 4,
                lastAccuracy: nil
            ),
            ExerciseInfo(
                id: "rec_3",
                title: "Mùa xuân đến",
                preview: "Mùa xuân đến rồi, hoa nở khắp nơi...",
                category: selectedCategory,
                difficulty: selectedDifficulty,
                estimatedTime: 5,
                lastAccuracy: nil
            )
        ]
    }
    
    private func getRecentExercises() -> [ExerciseInfo] {
        // This would fetch recent exercises from user history
        return [
            ExerciseInfo(
                id: "recent_1",
                title: "Bài thơ về mẹ",
                preview: "Mẹ ơi, mẹ yêu dấu! Con yêu mẹ nhiều lắm...",
                category: .poem,
                difficulty: .grade2,
                estimatedTime: 4,
                lastAccuracy: 0.92
            ),
            ExerciseInfo(
                id: "recent_2",
                title: "Chuyến đi picnic",
                preview: "Cuối tuần, gia đình tôi đi picnic...",
                category: .story,
                difficulty: .grade2,
                estimatedTime: 6,
                lastAccuracy: 0.88
            )
        ]
    }
}

// MARK: - Exercise Info Model
struct ExerciseInfo {
    let id: String
    let title: String
    let preview: String
    let category: ExerciseCategory
    let difficulty: DifficultyLevel
    let estimatedTime: Int // in minutes
    let lastAccuracy: Float?
}

// MARK: - Exercise Category Extension
extension ExerciseCategory {
    var color: Color {
        switch self {
        case .story:
            return .blue
        case .poem:
            return .purple
        case .instruction:
            return .green
        case .description:
            return .orange
        case .news:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .story:
            return "book.fill"
        case .poem:
            return "quote.bubble.fill"
        case .instruction:
            return "list.bullet"
        case .description:
            return "doc.text.fill"
        case .news:
            return "newspaper.fill"
        }
    }
    
    var localizedName: String {
        switch self {
        case .story:
            return "Truyện"
        case .poem:
            return "Thơ"
        case .instruction:
            return "Hướng dẫn"
        case .description:
            return "Mô tả"
        case .news:
            return "Tin tức"
        }
    }
    
    var description: String {
        switch self {
        case .story:
            return "Câu chuyện thú vị"
        case .poem:
            return "Bài thơ hay"
        case .instruction:
            return "Hướng dẫn làm việc"
        case .description:
            return "Mô tả sự vật"
        case .news:
            return "Tin tức thời sự"
        }
    }
}

// MARK: - Difficulty Level Extension
extension DifficultyLevel {
    var color: Color {
        switch self {
        case .grade1:
            return .green
        case .grade2:
            return .blue
        case .grade3:
            return .orange
        case .grade4:
            return .purple
        case .grade5:
            return .red
        }
    }
}

// MARK: - Preview
struct PracticeTabView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeTabView(viewModel: MainMenuViewModel())
            .background(Color(.systemGroupedBackground))
    }
}