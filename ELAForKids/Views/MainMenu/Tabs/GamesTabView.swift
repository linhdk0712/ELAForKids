import SwiftUI

// MARK: - Games Tab View
struct GamesTabView: View {
    @ObservedObject var viewModel: MainMenuViewModel
    @State private var selectedGameCategory: GameCategory = .all
    @State private var showingGameDetail = false
    @State private var selectedGame: GameInfo?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header section
                headerSection
                
                // Category filter
                categoryFilterSection
                
                // Featured games
                featuredGamesSection
                
                // All games
                allGamesSection
                
                // Coming soon
                comingSoonSection
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
                Image(systemName: "gamecontroller.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trò chơi học tập")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Học qua chơi, chơi mà học")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Fun fact
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Trò chơi giúp bé học nhanh hơn 40%!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Category Filter Section
    
    @ViewBuilder
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GameCategory.allCases, id: \.self) { category in
                    categoryFilterButton(category)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private func categoryFilterButton(_ category: GameCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGameCategory = category
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                
                Text(category.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedGameCategory == category ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedGameCategory == category ? Color.purple : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Featured Games Section
    
    @ViewBuilder
    private var featuredGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trò chơi nổi bật")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(getFeaturedGames(), id: \.id) { game in
                        featuredGameCard(game)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private func featuredGameCard(_ game: GameInfo) -> some View {
        Button(action: {
            selectedGame = game
            showingGameDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Game icon and badge
                HStack {
                    Image(systemName: game.icon)
                        .font(.system(size: 32))
                        .foregroundColor(game.color)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(game.color.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    if game.isNew {
                        Text("MỚI")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                
                // Game info
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(game.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(game.difficulty.localizedName, systemImage: "graduationcap.fill")
                            .font(.caption)
                            .foregroundColor(game.difficulty.color)
                        
                        Label("\(game.estimatedTime) phút", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Play button
                HStack {
                    Spacer()
                    
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(game.color)
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .frame(width: 200, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - All Games Section
    
    @ViewBuilder
    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tất cả trò chơi")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(getFilteredGames(), id: \.id) { game in
                    gameCard(game)
                }
            }
        }
    }
    
    @ViewBuilder
    private func gameCard(_ game: GameInfo) -> some View {
        Button(action: {
            selectedGame = game
            showingGameDetail = true
        }) {
            VStack(spacing: 12) {
                // Game icon
                Image(systemName: game.icon)
                    .font(.system(size: 40))
                    .foregroundColor(game.color)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(game.color.opacity(0.1))
                    )
                
                // Game info
                VStack(spacing: 4) {
                    Text(game.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(game.shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Game stats
                HStack(spacing: 8) {
                    if game.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("\(game.rating, specifier: "%.1f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(game.isLocked ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(game.isLocked ? Color.clear : game.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(game.isLocked)
    }
    
    // MARK: - Coming Soon Section
    
    @ViewBuilder
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sắp ra mắt")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(getComingSoonGames(), id: \.id) { game in
                    comingSoonCard(game)
                }
            }
        }
    }
    
    @ViewBuilder
    private func comingSoonCard(_ game: GameInfo) -> some View {
        HStack(spacing: 16) {
            // Game icon
            Image(systemName: game.icon)
                .font(.title2)
                .foregroundColor(game.color.opacity(0.6))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(game.color.opacity(0.1))
                )
            
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(game.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Coming soon badge
            Text("Sắp có")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray)
                .cornerRadius(12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFeaturedGames() -> [GameInfo] {
        return getAllGames().filter { $0.isFeatured }
    }
    
    private func getFilteredGames() -> [GameInfo] {
        let allGames = getAllGames()
        
        if selectedGameCategory == .all {
            return allGames
        } else {
            return allGames.filter { $0.category == selectedGameCategory }
        }
    }
    
    private func getComingSoonGames() -> [GameInfo] {
        return [
            GameInfo(
                id: "coming_1",
                title: "Tìm từ ẩn",
                description: "Tìm các từ ẩn trong bảng chữ cái",
                shortDescription: "Tìm từ ẩn",
                icon: "magnifyingglass",
                color: .cyan,
                category: .puzzle,
                difficulty: .grade2,
                estimatedTime: 8,
                rating: 0.0,
                isNew: false,
                isFeatured: false,
                isLocked: false
            ),
            GameInfo(
                id: "coming_2",
                title: "Câu đố chữ",
                description: "Giải các câu đố về từ vựng tiếng Việt",
                shortDescription: "Câu đố chữ",
                icon: "questionmark.circle",
                color: .indigo,
                category: .quiz,
                difficulty: .grade3,
                estimatedTime: 10,
                rating: 0.0,
                isNew: false,
                isFeatured: false,
                isLocked: false
            )
        ]
    }
    
    private func getAllGames() -> [GameInfo] {
        return [
            GameInfo(
                id: "word_match",
                title: "Ghép từ với hình",
                description: "Ghép các từ với hình ảnh tương ứng để học từ vựng",
                shortDescription: "Ghép từ",
                icon: "puzzlepiece.fill",
                color: .blue,
                category: .matching,
                difficulty: .grade1,
                estimatedTime: 5,
                rating: 4.8,
                isNew: false,
                isFeatured: true,
                isLocked: false
            ),
            GameInfo(
                id: "speed_reading",
                title: "Đọc nhanh",
                description: "Thử thách tốc độ đọc và hiểu nội dung",
                shortDescription: "Đọc nhanh",
                icon: "bolt.fill",
                color: .orange,
                category: .speed,
                difficulty: .grade3,
                estimatedTime: 3,
                rating: 4.6,
                isNew: true,
                isFeatured: true,
                isLocked: false
            ),
            GameInfo(
                id: "pronunciation",
                title: "Luyện phát âm",
                description: "Luyện phát âm chuẩn với trò chơi thú vị",
                shortDescription: "Phát âm",
                icon: "mic.fill",
                color: .green,
                category: .pronunciation,
                difficulty: .grade2,
                estimatedTime: 7,
                rating: 4.7,
                isNew: false,
                isFeatured: true,
                isLocked: false
            ),
            GameInfo(
                id: "memory_game",
                title: "Trí nhớ từ vựng",
                description: "Ghi nhớ và tìm các cặp từ giống nhau",
                shortDescription: "Trí nhớ",
                icon: "brain.head.profile",
                color: .purple,
                category: .memory,
                difficulty: .grade2,
                estimatedTime: 6,
                rating: 4.5,
                isNew: false,
                isFeatured: false,
                isLocked: false
            ),
            GameInfo(
                id: "word_builder",
                title: "Xây dựng từ",
                description: "Tạo từ mới từ các chữ cái cho sẵn",
                shortDescription: "Xây từ",
                icon: "textformat.abc",
                color: .red,
                category: .puzzle,
                difficulty: .grade3,
                estimatedTime: 8,
                rating: 4.4,
                isNew: false,
                isFeatured: false,
                isLocked: false
            ),
            GameInfo(
                id: "story_quiz",
                title: "Câu hỏi truyện",
                description: "Trả lời câu hỏi về nội dung truyện vừa đọc",
                shortDescription: "Hỏi truyện",
                icon: "questionmark.bubble.fill",
                color: .teal,
                category: .quiz,
                difficulty: .grade4,
                estimatedTime: 10,
                rating: 4.3,
                isNew: false,
                isFeatured: false,
                isLocked: viewModel.userLevel < 5
            ),
            GameInfo(
                id: "rhyme_time",
                title: "Thời gian vần điệu",
                description: "Tìm các từ có vần điệu giống nhau",
                shortDescription: "Vần điệu",
                icon: "music.note",
                color: .pink,
                category: .matching,
                difficulty: .grade2,
                estimatedTime: 5,
                rating: 4.6,
                isNew: false,
                isFeatured: false,
                isLocked: false
            ),
            GameInfo(
                id: "sentence_builder",
                title: "Xây dựng câu",
                description: "Sắp xếp các từ để tạo thành câu có nghĩa",
                shortDescription: "Xây câu",
                icon: "text.alignleft",
                color: .brown,
                category: .puzzle,
                difficulty: .grade4,
                estimatedTime: 12,
                rating: 4.2,
                isNew: false,
                isFeatured: false,
                isLocked: viewModel.userLevel < 8
            )
        ]
    }
}

// MARK: - Game Category Enum

enum GameCategory: String, CaseIterable {
    case all = "all"
    case matching = "matching"
    case puzzle = "puzzle"
    case speed = "speed"
    case pronunciation = "pronunciation"
    case memory = "memory"
    case quiz = "quiz"
    
    var title: String {
        switch self {
        case .all:
            return "Tất cả"
        case .matching:
            return "Ghép đôi"
        case .puzzle:
            return "Câu đố"
        case .speed:
            return "Tốc độ"
        case .pronunciation:
            return "Phát âm"
        case .memory:
            return "Trí nhớ"
        case .quiz:
            return "Trắc nghiệm"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .matching:
            return "puzzlepiece.fill"
        case .puzzle:
            return "brain.head.profile"
        case .speed:
            return "bolt.fill"
        case .pronunciation:
            return "mic.fill"
        case .memory:
            return "memorychip"
        case .quiz:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Game Info Model

struct GameInfo {
    let id: String
    let title: String
    let description: String
    let shortDescription: String
    let icon: String
    let color: Color
    let category: GameCategory
    let difficulty: DifficultyLevel
    let estimatedTime: Int // in minutes
    let rating: Double
    let isNew: Bool
    let isFeatured: Bool
    let isLocked: Bool
}

// MARK: - Preview
struct GamesTabView_Previews: PreviewProvider {
    static var previews: some View {
        GamesTabView(viewModel: MainMenuViewModel())
            .background(Color(.systemGroupedBackground))
    }
}