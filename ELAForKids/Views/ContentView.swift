import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.navigationCoordinator) private var navigationCoordinator
    
    var body: some View {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Học Tiếng Việt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Cùng học viết và đọc nhé!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main Menu Buttons
                VStack(spacing: 20) {
                    MenuButton(
                        title: "Bắt đầu học",
                        subtitle: "Viết và đọc văn bản",
                        icon: "pencil.and.outline",
                        color: .green
                    ) {
                        navigationCoordinator.navigate(to: .textInput)
                    }
                    
                    MenuButton(
                        title: "Xem tiến độ",
                        subtitle: "Điểm số và thành tích",
                        icon: "chart.bar.fill",
                        color: .orange
                    ) {
                        navigationCoordinator.navigate(to: .progress)
                    }
                    
                    MenuButton(
                        title: "Cài đặt",
                        subtitle: "Tùy chỉnh ứng dụng",
                        icon: "gearshape.fill",
                        color: .purple
                    ) {
                        navigationCoordinator.navigate(to: .settings)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                Text("Phiên bản \(ELAForKidsApp.appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Trang chủ")
            .navigationBarHidden(true)
    }
}

// MARK: - Menu Button Component
struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain) // Tránh default button styling
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone Preview
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .withNavigationCoordinator(NavigationCoordinator())
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone")
            
            // iPad Preview
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .withNavigationCoordinator(NavigationCoordinator())
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad")
            
            // Mac Preview
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .withNavigationCoordinator(NavigationCoordinator())
                .previewDevice("Mac")
                .previewDisplayName("Mac")
        }
    }
}