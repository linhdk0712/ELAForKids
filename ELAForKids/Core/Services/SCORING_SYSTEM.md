# Scoring System Documentation

## Overview

The Scoring System is a comprehensive gamification engine designed to motivate elementary school children in their Vietnamese language learning journey. It provides fair, encouraging, and educationally meaningful scoring that adapts to different difficulty levels and rewards consistent practice.

## Core Components

### 1. ScoreCalculator

**Purpose**: Central engine for calculating scores based on multiple factors including accuracy, difficulty, attempts, time, and streaks.

**Key Features**:
- **Multi-factor scoring** considering accuracy, difficulty, attempts, and time
- **Bonus point system** for streaks, perfect scores, and fast completion
- **Adaptive scoring** that adjusts to user's historical performance
- **Mistake severity consideration** for more nuanced scoring
- **Performance trend analysis** to track improvement over time

### 2. StreakManager

**Purpose**: Manages user streaks and milestone achievements to encourage consistent practice.

**Key Features**:
- **Streak tracking** with automatic reset after inactivity
- **Milestone rewards** at significant streak achievements
- **Streak levels** (Beginner, Bronze, Silver, Gold, Platinum, Diamond)
- **Bonus calculations** based on streak length
- **Inactivity handling** with grace periods

### 3. UserScoreRepository

**Purpose**: Persistent storage and retrieval of user scoring data with Core Data integration.

**Key Features**:
- **User score management** with level and experience tracking
- **Leaderboard functionality** for competitive elements
- **Achievement storage** and retrieval
- **Statistics calculation** for user profiles
- **Ranking system** for social comparison

## Scoring Algorithm

### Base Score Calculation

```swift
baseScore = difficultyLevel.baseScore * accuracy
```

**Difficulty Base Scores**:
- Grade 1: 100 points
- Grade 2: 150 points  
- Grade 3: 200 points
- Grade 4: 250 points
- Grade 5: 300 points

### Difficulty Multipliers

Applied to bonus calculations to reward higher difficulty attempts:

- Grade 1: 1.0x (no bonus)
- Grade 2: 1.2x
- Grade 3: 1.4x
- Grade 4: 1.6x
- Grade 5: 1.8x

### Bonus Point System

#### 1. Perfect Score Bonus
- **Condition**: 100% accuracy with no mistakes
- **Reward**: +100 points
- **Purpose**: Encourage precision and careful reading

#### 2. Streak Bonus
- **Formula**: `streakCount * 0.1 * 100` points
- **Examples**:
  - 3 streak: +30 points
  - 5 streak: +50 points
  - 10 streak: +100 points
- **Purpose**: Reward consistent practice

#### 3. Time Bonus
- **Condition**: Complete in <80% of target time
- **Formula**: `(timeSaved / targetTime) * 200` points
- **Maximum**: 200 bonus points
- **Purpose**: Encourage fluency and confidence

#### 4. Difficulty Bonus
- **Formula**: `baseScore * (multiplier - 1.0)`
- **Purpose**: Reward attempting harder content

### Penalty System

#### 1. Attempt Penalty
- **Formula**: `accuracyScore * 0.15 * (attempts - 1)`
- **Purpose**: Encourage getting it right the first time
- **Note**: Only applies after first attempt

#### 2. Mistake Severity Penalty
- **Minor mistakes**: -5 points each
- **Moderate mistakes**: -15 points each
- **Major mistakes**: -30 points each
- **Purpose**: Differentiate between small errors and significant problems

### Final Score Calculation

```swift
finalScore = min(1000, max(0, 
    accuracyScore + 
    difficultyBonus + 
    timeBonusPoints + 
    streakBonusPoints + 
    perfectScoreBonus - 
    attemptPenalty - 
    mistakeSeverityPenalty
))
```

## Streak System

### Streak Requirements
- **Minimum accuracy**: 80% to maintain streak
- **Reset conditions**: 
  - Accuracy below 80%
  - 7 days of inactivity
- **Grace period**: Streak maintained for up to 7 days without activity

### Streak Milestones

| Streak | Title | Reward | Badge |
|--------|-------|---------|-------|
| 3 | Khởi đầu tốt! | 25 points | 🔥 |
| 5 | Kiên trì! | 50 points | ⭐ |
| 7 | Một tuần hoàn hảo! | 75 points | 🏆 |
| 10 | Thành thạo! | 100 points | 💎 |
| 15 | Chuyên gia nhỏ! | 150 points | 👑 |
| 20 | Siêu sao đọc! | 200 points | 🌟 |
| 25 | Bậc thầy ngôn ngữ! | 250 points | 🎖️ |
| 30 | Huyền thoại! | 300 points | 🏅 |
| 50 | Vô địch toàn quốc! | 500 points | 🥇 |
| 100 | Thần đồng tiếng Việt! | 1000 points | 🎯 |

### Streak Levels

| Level | Range | Name | Color | Emoji |
|-------|-------|------|-------|-------|
| Beginner | 0-2 | Người mới | Gray | 🌱 |
| Bronze | 3-7 | Đồng | Brown | 🥉 |
| Silver | 8-15 | Bạc | Silver | 🥈 |
| Gold | 16-30 | Vàng | Gold | 🥇 |
| Platinum | 31-50 | Bạch kim | Platinum | 💎 |
| Diamond | 51+ | Kim cương | Diamond | 💠 |

## Level and Experience System

### Experience Calculation
- **Base experience**: `score * 1.5`
- **Bonus experience**: Additional experience for achievements and milestones

### Level Progression
- **Level 1**: 0-99 experience
- **Level 2**: 100-299 experience  
- **Level 3**: 300-599 experience
- **Formula**: `experienceRequired = 100 * level + 50 * (level-1) * level`

### Level Benefits
- **Visual progression**: Progress bars and level badges
- **Unlocked content**: Higher levels unlock advanced exercises
- **Social status**: Level displayed in leaderboards and profiles

## Performance Categories

Based on accuracy percentage:

| Category | Range | Vietnamese | Emoji | Color |
|----------|-------|------------|-------|-------|
| Excellent | 95-100% | Xuất sắc | 🌟 | Green |
| Good | 85-94% | Tốt | 👏 | Blue |
| Fair | 70-84% | Khá | 😊 | Orange |
| Needs Improvement | <70% | Cần cải thiện | 💪 | Red |

## Adaptive Scoring Features

### 1. Personal Improvement Bonus
- **Condition**: Current accuracy > user's average accuracy
- **Bonus**: `(currentAccuracy - averageAccuracy) * 200` points
- **Purpose**: Reward personal growth over absolute performance

### 2. Difficulty Adaptation
- **Smart recommendations**: Suggest appropriate difficulty based on recent performance
- **Gradual progression**: Encourage moving to higher difficulties when ready
- **Safety net**: Prevent frustration by not penalizing difficulty exploration

### 3. Performance Trend Analysis
- **Improving trend**: Recent sessions show increasing accuracy
- **Declining trend**: Recent sessions show decreasing accuracy  
- **Stable trend**: Consistent performance over time
- **Feedback**: Provide encouraging messages based on trends

## Integration Points

### 1. Text Comparison Engine
```swift
let comparisonResult = textComparator.compareTexts(original: original, spoken: spoken)
let scoringResult = scoreCalculator.calculateComprehensiveScore(
    accuracy: comparisonResult.accuracy,
    attempts: sessionAttempts,
    difficulty: exerciseDifficulty,
    completionTime: sessionTime,
    streak: currentStreak,
    mistakes: comparisonResult.mistakes
)
```

### 2. User Interface
```swift
// Display score breakdown
ScoreBreakdownView(scoringResult: result.scoringResult)

// Show streak progress
StreakProgressView(
    currentStreak: streakManager.getCurrentStreak(),
    nextMilestone: streakManager.getNextMilestone()
)

// Leaderboard integration
LeaderboardView(topUsers: scoreCalculator.getLeaderboard(limit: 10))
```

### 3. Achievement System
```swift
// Check for new achievements after scoring
let achievements = achievementManager.checkForNewAchievements(
    sessionResult: sessionResult,
    scoringResult: scoringResult
)
```

## Data Models

### ScoringResult
Complete scoring breakdown with all components:
- Base score and accuracy score
- All bonus points (difficulty, time, streak, perfect)
- Penalties (attempts, mistake severity)
- Final score and experience gained
- Performance category and breakdown

### UserScore
Persistent user scoring data:
- Total score and current level
- Experience points and level progress
- Current streak and best streak
- Achievement list and timestamps

### SessionResult
Individual session data:
- Exercise details and user input
- Accuracy and mistake analysis
- Time spent and attempt count
- Scoring result and comparison result

## Educational Design Principles

### 1. Encouraging Feedback
- **Positive messaging**: All feedback uses encouraging language
- **Growth mindset**: Focus on improvement rather than absolute performance
- **Age-appropriate**: Language and concepts suitable for elementary students

### 2. Fair Assessment
- **Multiple factors**: Score considers effort, improvement, and consistency
- **Difficulty scaling**: Higher difficulty appropriately rewarded
- **Mistake differentiation**: Minor errors less penalized than major ones

### 3. Motivation Maintenance
- **Achievable goals**: Milestones set at reasonable intervals
- **Variety in rewards**: Different types of recognition (points, badges, levels)
- **Social elements**: Leaderboards and sharing for motivation

### 4. Learning Support
- **Adaptive difficulty**: System suggests appropriate challenge levels
- **Progress tracking**: Clear visualization of improvement over time
- **Specific feedback**: Detailed breakdown helps identify areas for improvement

## Performance Considerations

### 1. Calculation Efficiency
- **Cached calculations**: Frequently used values cached appropriately
- **Batch operations**: Multiple score updates processed efficiently
- **Background processing**: Heavy calculations performed off main thread

### 2. Data Storage
- **Core Data integration**: Efficient persistence with proper relationships
- **Query optimization**: Leaderboard and ranking queries optimized
- **Data cleanup**: Old session data archived appropriately

### 3. Memory Management
- **Weak references**: Proper memory management in delegates and closures
- **Resource cleanup**: Timers and observers properly disposed
- **Batch size limits**: Large data sets processed in manageable chunks

## Testing Strategy

### 1. Unit Tests
- **Score calculation accuracy**: All formulas tested with edge cases
- **Bonus point logic**: Each bonus type tested independently
- **Penalty application**: Penalty calculations verified
- **Data model validation**: All data structures tested for correctness

### 2. Integration Tests
- **End-to-end scoring**: Complete scoring flow from session to storage
- **Streak management**: Streak updates and milestone detection
- **Repository operations**: Data persistence and retrieval
- **Performance testing**: Large dataset handling

### 3. User Experience Tests
- **Child usability**: Age-appropriate interface and feedback
- **Motivation effectiveness**: Scoring system encourages continued use
- **Educational value**: Scoring supports learning objectives
- **Accessibility**: System works for users with different needs

## Future Enhancements

### 1. Advanced Analytics
- **Learning pattern analysis**: Identify optimal practice schedules
- **Difficulty progression modeling**: Personalized difficulty recommendations
- **Peer comparison insights**: Anonymous comparison with similar users
- **Teacher dashboard**: Progress reports for educators

### 2. Enhanced Gamification
- **Seasonal events**: Special scoring events and challenges
- **Team competitions**: Group-based scoring and achievements
- **Customizable rewards**: User-chosen reward preferences
- **Virtual currency**: Points exchangeable for app customizations

### 3. AI-Powered Features
- **Personalized scoring**: Machine learning optimized scoring weights
- **Predictive difficulty**: AI-suggested next exercises
- **Emotional state consideration**: Scoring adjusted for user mood
- **Adaptive feedback**: Personalized encouragement messages

## Conclusion

The Scoring System provides a comprehensive, fair, and motivating framework for recognizing student achievement in Vietnamese language learning. By considering multiple factors and providing detailed feedback, it supports both learning objectives and user engagement while maintaining educational integrity and age-appropriate design principles.

The system successfully addresses requirement 4.3 (scoring when reading correctly) and 4.5 (bonus points for corrections) while providing a rich foundation for the broader gamification and achievement systems.