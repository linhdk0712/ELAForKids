# 🔌 Protocols Documentation - ELAForKids

## Tổng quan

Protocols trong ELAForKids được thiết kế để tạo ra abstraction layer rõ ràng giữa các components, giúp:
- Tách biệt implementation khỏi interface
- Dễ dàng testing với mock implementations
- Flexibility trong việc thay đổi implementations
- Clear contracts giữa các modules

## Protocol Categories

### 1. Text Input Protocols

#### TextInputProtocol
**Purpose**: Định nghĩa interface cho text input handling
**Key Methods**:
- `startTextInput()` - Bắt đầu text input session
- `processKeyboardInput(_:)` - Xử lý keyboard input
- `processPencilInput(_:)` - Xử lý Apple Pencil input
- `finishTextInput()` - Kết thúc và return final text
- `validateInput(_:)` - Validate input text

#### HandwritingRecognitionProtocol
**Purpose**: Abstraction cho handwriting recognition
**Key Methods**:
- `recognizeText(from:)` - Convert drawing to text
- `getConfidenceScore()` - Get recognition confidence
- `isRecognitionAvailable()` - Check availability

### 2. Speech Recognition Protocols

#### SpeechRecognitionProtocol
**Purpose**: Interface cho speech recognition functionality
**Key Methods**:
- `requestPermissions()` - Request microphone permissions
- `startRecording()` - Start audio recording
- `stopRecording()` - Stop audio recording
- `convertSpeechToText()` - Convert audio to text
- `isAvailable()` - Check if speech recognition is available

#### AudioRecordingProtocol
**Purpose**: Audio recording và playback management
**Key Methods**:
- `startRecording()` - Start recording
- `stopRecording()` - Stop recording
- `getRecordingDuration()` - Get current duration
- `playback()` - Play recorded audio

#### TextComparisonProtocol
**Purpose**: Compare original text với spoken text
**Key Methods**:
- `compareTexts(original:spoken:)` - Compare two texts
- `identifyMistakes(original:spoken:)` - Find specific mistakes
- `calculateAccuracy(original:spoken:)` - Calculate accuracy percentage
- `generateFeedback(comparisonResult:)` - Generate user feedback

### 3. Scoring System Protocols

#### ScoringProtocol
**Purpose**: Score calculation và user score management
**Key Methods**:
- `calculateScore(accuracy:attempts:difficulty:)` - Calculate session score
- `calculateBonusPoints(streak:perfectScore:)` - Calculate bonus points
- `updateUserScore(userId:score:)` - Update user's total score
- `getLeaderboard(limit:)` - Get top users
- `getUserRanking(userId:)` - Get user's rank

#### AchievementProtocol
**Purpose**: Achievement system management
**Key Methods**:
- `checkForNewAchievements(sessionResult:)` - Check for unlocked achievements
- `unlockAchievement(_:for:)` - Unlock specific achievement
- `getUserAchievements(userId:)` - Get user's achievements
- `getAvailableAchievements()` - Get all available achievements

#### ProgressTrackingProtocol
**Purpose**: User progress tracking
**Key Methods**:
- `updateDailyProgress(userId:sessionResult:)` - Update daily stats
- `getUserProgress(userId:period:)` - Get progress for period
- `checkDailyGoal(userId:)` - Check if daily goal met

### 4. Repository Protocols

#### RepositoryProtocol
**Purpose**: Base protocol cho all repositories
**Key Methods**:
- `create(_:)` - Create new entity
- `read(id:)` - Read entity by ID
- `update(_:)` - Update existing entity
- `delete(id:)` - Delete entity
- `list(limit:offset:)` - List entities with pagination

#### ExerciseRepositoryProtocol
**Purpose**: Exercise data management
**Extends**: RepositoryProtocol
**Additional Methods**:
- `findByDifficulty(_:)` - Find exercises by difficulty
- `getRandomExercise(difficulty:)` - Get random exercise
- `createDefaultExercises()` - Create default exercise set

#### UserSessionRepositoryProtocol
**Purpose**: User session data management
**Extends**: RepositoryProtocol
**Additional Methods**:
- `findByUser(_:)` - Find sessions by user
- `findByDateRange(userId:from:to:)` - Find sessions in date range
- `getUserStats(userId:)` - Get user statistics

### 5. Use Case Protocols

#### UseCaseProtocol
**Purpose**: Base protocol cho all use cases
**Generic Types**:
- `Input` - Input parameter type
- `Output` - Return value type
**Key Methods**:
- `execute(input:)` - Execute use case with input

#### Specific Use Case Protocols
- `ProcessTextInputUseCaseProtocol` - Process text input
- `StartSpeechRecognitionUseCaseProtocol` - Start speech recognition
- `CalculateScoreUseCaseProtocol` - Calculate session score
- `CheckAchievementsUseCaseProtocol` - Check for achievements
- `GetUserProgressUseCaseProtocol` - Get user progress

## Data Models

### Core Models
- `TextInputState` - State cho text input
- `SpeechRecognitionState` - State cho speech recognition
- `ScoringState` - State cho scoring system
- `ValidationResult` - Text validation result
- `RecognitionResult` - Handwriting recognition result
- `ComparisonResult` - Text comparison result
- `TextMistake` - Individual mistake information
- `Achievement` - Achievement data
- `UserScore` - User score information
- `SessionResult` - Complete session result

### Enums
- `InputMethod` - Keyboard, Pencil, Voice
- `MistakeType` - Mispronunciation, Omission, Insertion, Substitution
- `MistakeSeverity` - Minor, Moderate, Major
- `ScoreCategory` - Excellent, Good, Fair, NeedsImprovement
- `AchievementCategory` - Reading, Accuracy, Streak, Volume, Speed, Special
- `DifficultyLevel` - Grade1 through Grade5
- `ExerciseCategory` - Story, Poem, Dialogue, Description, etc.

## Mock Implementations

Để support development và testing, tất cả protocols đều có mock implementations:

### MockTextInputHandler
- Simulates keyboard và pencil input
- Returns sample text for testing
- Validates input according to rules

### MockSpeechRecognitionManager
- Simulates speech recognition process
- Returns sample recognized text
- Handles permission requests

### MockTextComparator
- Compares texts using simple algorithm
- Generates realistic mistakes
- Calculates accuracy scores

### MockScoreCalculator
- Calculates scores based on accuracy và difficulty
- Applies bonus points for streaks
- Maintains sample leaderboard

### MockAchievementManager
- Tracks achievement progress
- Unlocks achievements based on criteria
- Provides sample achievements

## Usage Examples

### Text Input
```swift
@Injected(TextInputProtocol.self) var textInputHandler

// Start text input
textInputHandler.startTextInput()

// Process keyboard input
textInputHandler.processKeyboardInput("Con mèo ngồi trên thảm")

// Validate input
let validation = textInputHandler.validateInput(text)

// Finish input
let finalText = textInputHandler.finishTextInput()
```

### Speech Recognition
```swift
@Injected(SpeechRecognitionProtocol.self) var speechRecognizer

// Request permissions
let hasPermission = await speechRecognizer.requestPermissions()

// Start recording
try await speechRecognizer.startRecording()

// Stop and convert
try await speechRecognizer.stopRecording()
let recognizedText = try await speechRecognizer.convertSpeechToText()
```

### Text Comparison
```swift
@Injected(TextComparisonProtocol.self) var textComparator

let result = textComparator.compareTexts(
    original: "Con mèo ngồi trên thảm",
    spoken: "Con mèo ngồi trên ghế"
)

print("Accuracy: \(result.accuracy)")
print("Mistakes: \(result.mistakes.count)")
```

### Scoring
```swift
@Injected(ScoringProtocol.self) var scoreCalculator

let score = scoreCalculator.calculateScore(
    accuracy: 0.85,
    attempts: 2,
    difficulty: .grade2
)

let bonus = scoreCalculator.calculateBonusPoints(
    streak: 5,
    perfectScore: false
)
```

## Testing Strategy

### Unit Testing
- Test each protocol implementation independently
- Use mock implementations for dependencies
- Verify contract compliance
- Test error conditions

### Integration Testing
- Test protocol interactions
- Verify data flow between components
- Test real implementations với mock data

### Mock Testing
- Verify mock implementations behave correctly
- Test edge cases với predictable mock data
- Validate mock data consistency

## Best Practices

### Protocol Design
1. **Single Responsibility**: Mỗi protocol có một responsibility rõ ràng
2. **Async/Await**: Sử dụng modern concurrency cho async operations
3. **Error Handling**: Proper error types và handling
4. **Generic Types**: Use generics where appropriate
5. **Documentation**: Clear documentation cho all methods

### Implementation Guidelines
1. **Dependency Injection**: Always use DI cho protocol dependencies
2. **Mock First**: Implement mocks trước real implementations
3. **Testing**: Write tests cho both mocks và real implementations
4. **Error Handling**: Handle all error cases gracefully
5. **Performance**: Consider performance implications

### Naming Conventions
- Protocol names end với "Protocol"
- Method names are descriptive và action-oriented
- Use consistent parameter naming
- Follow Swift naming guidelines

## Future Enhancements

### Planned Protocols
- `CloudSyncProtocol` - Cloud synchronization
- `AnalyticsProtocol` - Usage analytics
- `NotificationProtocol` - Push notifications
- `ExportProtocol` - Data export functionality
- `BackupProtocol` - Data backup và restore

### Protocol Extensions
- Add more specific error types
- Enhanced validation rules
- More sophisticated scoring algorithms
- Advanced achievement criteria
- Better progress tracking metrics