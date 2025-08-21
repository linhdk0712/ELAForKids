import SwiftUI

struct RootView: View {
    @Environment(\.navigationCoordinator) private var navigationCoordinator
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            ContentView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    navigationCoordinator.view(for: destination)
                }
        }
        .sheet(item: Binding<NavigationDestination?>(
            get: { navigationCoordinator.presentedSheet },
            set: { _ in navigationCoordinator.dismissSheet() }
        )) { destination in
            NavigationStack {
                navigationCoordinator.view(for: destination)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Đóng") {
                                navigationCoordinator.dismissSheet()
                            }
                        }
                    }
            }
        }
        .fullScreenCover(item: Binding<NavigationDestination?>(
            get: { navigationCoordinator.presentedFullScreenCover },
            set: { _ in navigationCoordinator.dismissFullScreenCover() }
        )) { destination in
            NavigationStack {
                navigationCoordinator.view(for: destination)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Đóng") {
                                navigationCoordinator.dismissFullScreenCover()
                            }
                        }
                    }
            }
        }
        .alert("Có lỗi xảy ra", isPresented: $errorHandler.showErrorAlert) {
            Button("Thử lại") {
                errorHandler.clearError()
                // Could add retry logic here
            }
            Button("Đóng", role: .cancel) {
                errorHandler.clearError()
            }
        } message: {
            if let error = errorHandler.currentError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - NavigationDestination Identifiable Conformance
extension NavigationDestination: Identifiable {
    var id: String {
        switch self {
        case .textInput:
            return "textInput"
        case .reading(let text):
            return "reading_\(text.hashValue)"
        case .results(let result):
            return "results_\(result.id)"
        case .progress:
            return "progress"
        case .settings:
            return "settings"
        case .profile:
            return "profile"
        }
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .withNavigationCoordinator(NavigationCoordinator())
            .environmentObject(ErrorHandler())
    }
}