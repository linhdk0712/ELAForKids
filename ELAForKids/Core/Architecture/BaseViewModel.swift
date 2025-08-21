import Foundation
import Combine

// MARK: - Base ViewModel Protocol
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    func send(_ action: Action)
}

// MARK: - Base ViewModel Class
@MainActor
class BaseViewModel<State, Action>: ViewModelProtocol, ObservableObject {
    @Published private(set) var state: State
    
    private var cancellables = Set<AnyCancellable>()
    
    init(initialState: State) {
        self.state = initialState
    }
    
    func send(_ action: Action) {
        // Override trong subclasses
        fatalError("send(_:) must be implemented by subclasses")
    }
    
    // MARK: - State Management
    protected func updateState(_ newState: State) {
        state = newState
    }
    
    protected func updateState(_ transform: (inout State) -> Void) {
        var newState = state
        transform(&newState)
        state = newState
    }
    
    // MARK: - Combine Helpers
    protected func bind<T: Publisher>(
        _ publisher: T,
        to keyPath: WritableKeyPath<State, T.Output>
    ) where T.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updateState { state in
                    state[keyPath: keyPath] = value
                }
            }
            .store(in: &cancellables)
    }
    
    protected func bindAsync<T>(
        _ asyncOperation: @escaping () async throws -> T,
        to keyPath: WritableKeyPath<State, T?>,
        errorKeyPath: WritableKeyPath<State, Error?>? = nil
    ) {
        Task {
            do {
                let result = try await asyncOperation()
                await updateState { state in
                    state[keyPath: keyPath] = result
                    if let errorKeyPath = errorKeyPath {
                        state[keyPath: errorKeyPath] = nil
                    }
                }
            } catch {
                if let errorKeyPath = errorKeyPath {
                    await updateState { state in
                        state[keyPath: errorKeyPath] = error
                    }
                }
            }
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Loading State Helper
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}