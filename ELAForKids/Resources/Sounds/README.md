# Sound Effects for ELA for Kids

This directory contains all the sound effects used in the reward system. The sounds are designed to be child-friendly, encouraging, and culturally appropriate for Vietnamese children.

## Sound Categories

### Reward Sounds
- `reward_success.mp3` - Basic success sound for completing exercises
- `reward_good.mp3` - Good performance sound (70-84% accuracy)
- `reward_great.mp3` - Great performance sound (85-94% accuracy)
- `reward_excellent.mp3` - Excellent performance sound (95-99% accuracy)
- `reward_epic.mp3` - Epic sound for perfect scores (100% accuracy)
- `reward_legendary.mp3` - Legendary sound for major achievements
- `reward_bonus.mp3` - Bonus sound for speed bonuses and improvements

### Feedback Sounds
- `feedback_excellent.mp3` - Positive feedback for 95-100% accuracy
- `feedback_good.mp3` - Positive feedback for 85-94% accuracy
- `feedback_okay.mp3` - Neutral feedback for 70-84% accuracy
- `feedback_needs_improvement.mp3` - Encouraging feedback for <70% accuracy

### Streak Sounds
- `streak_start.mp3` - Sound for starting a streak (1-3 days)
- `streak_week.mp3` - Sound for weekly streak (4-7 days)
- `streak_strong.mp3` - Sound for strong streak (8-14 days)
- `streak_amazing.mp3` - Sound for amazing streak (15-30 days)
- `streak_legendary.mp3` - Sound for legendary streak (30+ days)

### Encouragement Voices (Vietnamese)
- `encouragement_great_job.mp3` - "Làm tốt lắm!" (Great job!)
- `encouragement_keep_going.mp3` - "Tiếp tục nào!" (Keep going!)
- `encouragement_almost_there.mp3` - "Sắp xong rồi!" (Almost there!)
- `encouragement_perfect.mp3` - "Hoàn hảo!" (Perfect!)
- `encouragement_try_again.mp3` - "Thử lại nào!" (Try again!)

### Background Music
- `background_learning.mp3` - Calm, focused music for learning sessions
- `background_celebration.mp3` - Upbeat music for celebrations and achievements
- `background_calm.mp3` - Relaxing music for quiet activities

## Sound Design Guidelines

### Technical Specifications
- **Format**: MP3, 44.1kHz, 16-bit
- **Duration**: 0.5-3 seconds for effects, 30-60 seconds for background music (looped)
- **Volume**: Normalized to -6dB to prevent clipping
- **Compression**: Moderate compression for consistent playback across devices

### Content Guidelines
- **Child-Friendly**: All sounds should be pleasant and non-startling for children
- **Cultural Sensitivity**: Vietnamese voice recordings should use clear, standard pronunciation
- **Educational**: Sounds should reinforce positive learning behaviors
- **Accessibility**: Clear, distinct sounds that work well with hearing aids

### Voice Recording Guidelines
- **Speaker**: Native Vietnamese speaker with clear pronunciation
- **Tone**: Warm, encouraging, and age-appropriate for 6-11 year olds
- **Speed**: Slightly slower than normal speech for clarity
- **Background**: Clean recording with no background noise

## Implementation Notes

### Audio Session Configuration
```swift
try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
```

### Volume Management
- Default volume: 70% of system volume
- User-adjustable from 0-100%
- Automatic ducking when other audio is playing

### Performance Considerations
- Sounds are preloaded at app launch for instant playback
- Background music uses streaming for memory efficiency
- Fallback to system sounds if custom sounds fail to load

## Localization

### Vietnamese Voice Files
All encouragement sounds include Vietnamese voice recordings:
- Clear pronunciation suitable for children learning to read
- Positive, encouraging tone
- Standard Vietnamese dialect (Northern/Hanoi accent)

### Future Localizations
The system is designed to support additional languages:
- Sound effect structure remains the same
- Voice encouragement files can be replaced per locale
- Background music is culturally neutral

## Testing

### Quality Assurance
- Test on various iOS devices (iPhone, iPad)
- Verify playback with different system volume levels
- Test with VoiceOver and accessibility features enabled
- Validate with children in target age group (6-11 years)

### Performance Testing
- Memory usage during sound preloading
- Latency between trigger and playback
- Battery impact during extended use
- Behavior during phone calls and other audio interruptions

## File Naming Convention

```
[category]_[type]_[variant].mp3

Examples:
- reward_excellent.mp3
- feedback_good.mp3
- streak_week.mp3
- encouragement_great_job.mp3
- background_learning.mp3
```

## Copyright and Licensing

All sound effects should be:
- Original compositions or royalty-free
- Licensed for commercial use in educational apps
- Appropriate for children's content
- Compliant with app store guidelines

## Future Enhancements

### Planned Features
- Dynamic music that adapts to user performance
- Personalized encouragement messages
- Seasonal sound themes (holidays, seasons)
- Achievement-specific musical stingers

### Technical Improvements
- Spatial audio support for newer devices
- Adaptive audio quality based on device capabilities
- Machine learning for optimal sound timing
- Integration with system haptics for synchronized feedback