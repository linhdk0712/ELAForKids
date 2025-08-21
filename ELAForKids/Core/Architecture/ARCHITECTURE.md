# 🏗️ Architecture Documentation - ELAForKids

## Tổng quan Kiến trúc

ELAForKids sử dụng **MVVM (Model-View-ViewModel)** pattern kết hợp với **Clean Architecture** principles để đảm bảo:
- Separation of concerns
- Testability
- Maintainability
- Scalability

## Cấu trúc Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   SwiftUI   │  │  ViewModels │  │  Navigation Router  │  │
│  │    Views    │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Entities  │  │ Use Cases   │  │   Repository        │  │
│  │             │  │             │  │   Protocols         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repositories│  │   Core Data │  │   External APIs     │  │
│  │             │  │   Storage   │  │   (Speech/Vision)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. BaseViewModel
- **Location**: `Core/Architecture/BaseViewModel.swift`
- **Purpose**: Base class cho tất cả ViewModels
- **Features**:
  - Generic State và Action handling
  - Combine integration
  - Async operation binding
  - Loading state management

```swift
@MainActor
class BaseViewModel<State, Action>: ViewModelProtocol, ObservableObject {
    @Published private(set) var state: State
    
    func send(_ action: Action)
    func updateState(_ newState: State)
    func updateState(_ transform: (inout State) -> Void)
}
```

### 2. Dependency Injection Container
- **Location**: `Core/DependencyInjection/DIContainer.swift`
- **Purpose**: Quản lý dependencies và service registration
- **Features**:
  - Singleton pattern
  - Factory registration
  - Thread-safe operations
  - Property wrapper support

```swift
// Registration
DIContainer.shared.register(ServiceProtocol.self, instance: ServiceImplementation())

// Usage with property wrapper
@Injected(ServiceProtocol.self) var service
```

### 3. Navigation Coordinator
- **Location**: `Core/Navigation/NavigationCoordinator.swift`
- **Purpose**: Centralized navigation management
- **Features**:
  - NavigationStack integration
  - Sheet và FullScreenCover support
  - Type-safe navigation destinations
  - Environment integration

```swift
// Navigation
navigationCoordinator.navigate(to: .textInput)
navigationCoordinator.presentSheet(.settings)
```

### 4. Error Handling System
- **Location**: `Core/ErrorHandling/AppError.swift`
- **Purpose**: Centralized error management
- **Features**:
  - Localized error messages
  - Child-friendly error descriptions
  - Recovery suggestions
  - Error categorization

```swift
enum AppError: LocalizedError {
    case speechRecognitionFailed
    case microphonePermissionDenied
    // ...
}
```

## Data Flow

### 1. User Interaction Flow
```
User Action → View → ViewModel → Use Case → Repository → Data Source
                ↓
            State Update ← ViewModel ← Use Case ← Repository ← Data Source
                ↓
            UI Update
```

### 2. Navigation Flow
```
User Action → View → NavigationCoordinator → NavigationDestination → New View
```

### 3. Error Handling Flow
```
Error → ErrorHandler → AppError → Localized Message → User Alert
```

## Dependency Injection Strategy

### Service Registration
```swift
// In ELAForKidsApp.init()
private func setupDependencyInjection() {
    DIContainer.shared.registerServices()
    
    // App-level dependencies
    DIContainer.shared.register(NavigationCoordinator.self, instance: navigationCoordinator)
    DIContainer.shared.register(ErrorHandler.self, instance: errorHandler)
}
```

### Service Categories
1. **Core Services**: PersistenceController, ErrorHandler
2. **Repositories**: Data access layer implementations
3. **Use Cases**: Business logic implementations
4. **ViewModels**: Presentation layer (factory registration)

## Testing Strategy

### 1. Unit Testing
- **ViewModels**: Test state changes và business logic
- **Use Cases**: Test core functionality
- **Repositories**: Test data access với mock data

### 2. Integration Testing
- **Navigation**: Test navigation flows
- **Data Flow**: Test end-to-end data operations
- **Error Handling**: Test error scenarios

### 3. UI Testing
- **User Journeys**: Test complete user flows
- **Accessibility**: Test VoiceOver integration
- **Multi-platform**: Test trên different devices

## Best Practices

### 1. ViewModel Guidelines
- Sử dụng `@MainActor` cho UI updates
- Keep ViewModels focused và single-responsibility
- Use dependency injection cho external dependencies
- Implement proper error handling

### 2. Navigation Guidelines
- Use type-safe navigation destinations
- Keep navigation logic trong NavigationCoordinator
- Avoid deep navigation stacks
- Handle navigation state properly

### 3. Error Handling Guidelines
- Use specific error types
- Provide child-friendly error messages
- Include recovery suggestions
- Log errors cho debugging

### 4. Dependency Injection Guidelines
- Register services at app startup
- Use protocols cho abstraction
- Avoid circular dependencies
- Keep registration organized

## Performance Considerations

### 1. Memory Management
- Proper cleanup trong ViewModels
- Avoid retain cycles với Combine
- Use weak references where appropriate

### 2. State Management
- Minimize state updates
- Use efficient data structures
- Implement proper caching strategies

### 3. Navigation Performance
- Lazy loading của views
- Proper view lifecycle management
- Efficient navigation stack management

## Future Enhancements

### 1. Modular Architecture
- Split into feature modules
- Plugin architecture support
- Dynamic feature loading

### 2. Advanced DI Features
- Scoped dependencies
- Conditional registration
- Configuration-based registration

### 3. Enhanced Navigation
- Deep linking support
- Navigation analytics
- Custom transition animations

## Troubleshooting

### Common Issues
1. **DI Resolution Failures**: Check service registration
2. **Navigation Issues**: Verify destination types
3. **State Update Problems**: Ensure @MainActor usage
4. **Memory Leaks**: Check Combine subscriptions

### Debug Tools
- Xcode Memory Graph Debugger
- Instruments for performance profiling
- Console logging cho DI operations
- Navigation path debugging