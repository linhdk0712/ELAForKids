import Foundation

// MARK: - Dependency Injection Container
final class DIContainer {
    static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let queue = DispatchQueue(label: "DIContainer", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Registration
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.services[key] = instance
        }
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories[key] = factory
        }
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories[key] = {
                let instance = factory()
                self.services[key] = instance
                return instance
            }
        }
    }
    
    // MARK: - Resolution
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        return queue.sync {
            // Check if instance already exists
            if let instance = services[key] as? T {
                return instance
            }
            
            // Check if factory exists
            if let factory = factories[key] {
                let instance = factory() as! T
                return instance
            }
            
            fatalError("Service of type \(type) is not registered")
        }
    }
    
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        return queue.sync {
            // Check if instance already exists
            if let instance = services[key] as? T {
                return instance
            }
            
            // Check if factory exists
            if let factory = factories[key] {
                let instance = factory() as! T
                return instance
            }
            
            return nil
        }
    }
    
    // MARK: - Cleanup
    func removeAll() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
            self.factories.removeAll()
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection
@propertyWrapper
struct Injected<T> {
    private let type: T.Type
    
    init(_ type: T.Type) {
        self.type = type
    }
    
    var wrappedValue: T {
        DIContainer.shared.resolve(type)
    }
}

@propertyWrapper
struct OptionalInjected<T> {
    private let type: T.Type
    
    init(_ type: T.Type) {
        self.type = type
    }
    
    var wrappedValue: T? {
        DIContainer.shared.resolveOptional(type)
    }
}

// MARK: - Service Registration Helper
protocol ServiceRegistrable {
    static func registerServices()
}

extension DIContainer {
    func registerServices() {
        // Register core services
        registerCoreServices()
        registerRepositories()
        registerUseCases()
        registerViewModels()
        
        // Register mock services for development
        #if DEBUG
        registerMockServices()
        #endif
    }
    
    private func registerCoreServices() {
        // Persistence
        register(PersistenceController.self, instance: PersistenceController.shared)
        
        // Supporting services
        register(TextValidationService.self) { _ in
            TextValidationService()
        }
        
        register(AudioProcessingService.self) { _ in
            AudioProcessingService()
        }
        
        // Core services
        register(AchievementManager.self) { container in
            AchievementManager(
                achievementRepository: container.resolve(AchievementRepositoryProtocol.self),
                userScoreRepository: container.resolve(UserScoreRepositoryProtocol.self),
                notificationCenter: NotificationCenter.default
            )
        }
    }
    
    private func registerRepositories() {
        // Register Core Data repositories
        let context = PersistenceController.shared.container.viewContext
        
        register(ExerciseRepositoryProtocol.self, instance: ExerciseRepository(context: context))
        register(UserSessionRepositoryProtocol.self, instance: UserSessionRepository(context: context))
        register(UserProfileRepositoryProtocol.self, instance: UserProfileRepository(context: context))
        register(AchievementRepositoryProtocol.self, instance: AchievementRepository(context: context))
    }
    
    private func registerUseCases() {
        // Register text input use cases
        register(ProcessTextInputUseCaseProtocol.self) { container in
            ProcessTextInputUseCase(
                textInputHandler: container.resolve(TextInputProtocol.self),
                validationService: container.resolve(TextValidationService.self)
            )
        }
        
        register(ValidateTextUseCaseProtocol.self) { container in
            ValidateTextUseCase(
                validationService: container.resolve(TextValidationService.self)
            )
        }
        
        register(RecognizeHandwritingUseCaseProtocol.self) { container in
            RecognizeHandwritingUseCase(
                handwritingRecognizer: container.resolve(HandwritingRecognizer.self)
            )
        }
        
        // Register speech recognition use cases
        register(StartSpeechRecognitionUseCaseProtocol.self) { container in
            StartSpeechRecognitionUseCase(
                speechRecognitionManager: container.resolve(SpeechRecognitionProtocol.self)
            )
        }
        
        register(ProcessSpeechUseCaseProtocol.self) { container in
            ProcessSpeechUseCase(
                speechRecognitionManager: container.resolve(SpeechRecognitionProtocol.self),
                audioProcessor: container.resolve(AudioProcessingService.self)
            )
        }
        
        register(CompareTextsUseCaseProtocol.self) { container in
            CompareTextsUseCase(
                textComparator: container.resolve(TextComparisonProtocol.self)
            )
        }
        
        // Register scoring use cases
        register(CalculateScoreUseCaseProtocol.self) { container in
            CalculateScoreUseCase(
                scoreCalculator: container.resolve(ScoringProtocol.self),
                userScoreRepository: container.resolve(UserScoreRepositoryProtocol.self)
            )
        }
        
        register(UpdateUserScoreUseCaseProtocol.self) { container in
            UpdateUserScoreUseCase(
                userScoreRepository: container.resolve(UserScoreRepositoryProtocol.self),
                achievementManager: container.resolve(AchievementManager.self)
            )
        }
        
        register(CheckAchievementsUseCaseProtocol.self) { container in
            CheckAchievementsUseCase(
                achievementManager: container.resolve(AchievementManager.self)
            )
        }
        
        // Register user management use cases
        register(CreateUserUseCaseProtocol.self) { container in
            CreateUserUseCase(
                userProfileRepository: container.resolve(UserProfileRepositoryProtocol.self)
            )
        }
        
        register(GetUserProgressUseCaseProtocol.self) { container in
            GetUserProgressUseCase(
                progressRepository: container.resolve(ProgressRepositoryProtocol.self),
                userScoreRepository: container.resolve(UserScoreRepositoryProtocol.self)
            )
        }
        
        register(UpdateUserProgressUseCaseProtocol.self) { container in
            UpdateUserProgressUseCase(
                progressRepository: container.resolve(ProgressRepositoryProtocol.self)
            )
        }
        
        // Register exercise management use cases
        register(GetExerciseUseCaseProtocol.self) { container in
            GetExerciseUseCase(
                exerciseRepository: container.resolve(ExerciseRepositoryProtocol.self)
            )
        }
        
        register(CreateExerciseUseCaseProtocol.self) { container in
            CreateExerciseUseCase(
                exerciseRepository: container.resolve(ExerciseRepositoryProtocol.self)
            )
        }
        
        register(GetExerciseListUseCaseProtocol.self) { container in
            GetExerciseListUseCase(
                exerciseRepository: container.resolve(ExerciseRepositoryProtocol.self)
            )
        }
    }
    
    private func registerViewModels() {
        // ViewModels are typically created fresh each time
        // So we'll register factories instead of singletons
    }
    
    private func registerMockServices() {
        // Register real implementations where available
        register(TextInputProtocol.self, instance: TextInputHandler())
        register(HandwritingRecognitionProtocol.self, instance: HandwritingRecognizer())
        register(SpeechRecognitionProtocol.self, instance: SpeechRecognitionManager())
        register(AudioRecordingProtocol.self, instance: AudioRecordingManager())
        register(TextComparisonProtocol.self, instance: TextComparisonEngine())
        
        // Register mock implementations for development and testing
        register(ScoringProtocol.self, instance: MockScoreCalculator())
        register(AchievementProtocol.self, instance: MockAchievementManager())
    }
}
