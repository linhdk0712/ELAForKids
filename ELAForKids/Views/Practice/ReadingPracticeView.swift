import SwiftUI
import Speech
import AVFoundation

// MARK: - Reading Practice View
struct ReadingPracticeView: View {
    let config: PracticeSessionConfig
    @StateObject private var viewModel = ReadingPracticeViewModel()
    @StateObject private var speechCoordinator = SpeechAndTTSCoordinator()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var rewardSystem: RewardSystem
    
    @State private var showingExitConfirmation = false
    @State private var showingInstructions = true
    @State private var currentAttempt: ReadingAttempt?
    @State private var showingFeedback = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Practice content
                practiceContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Controls
                controlsView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startSession(config: config)
        }
        .onDisappear {
            viewModel.endSession()
        }
        .sheet(isPresented: $showingInstructions) {
            InstructionsView(
                difficulty: config.difficulty,
                mode: config.mode,
                onStart: {
                    showingInstructions = false
                    viewModel.beginReading()
                }
            )
        }
        .alert("Thoát luyện tập?", isPresented: $showingExitConfirmation) {
            Button("Tiếp tục", role: .cancel) {}
            Button("Thoát", role: .destructive) {
                navigationCoordinator.returnToMainMenu()
            }
        } message: {
            Text("Bé có chắc muốn thoát không? Tiến độ sẽ không được lưu.")
        }
        .onChange(of: viewModel.sessionCompleted) { completed in
            if completed, let result = viewModel.sessionResult {
                accessibilityManager.announceToVoiceOver(
                    "Hoàn thành bài luyện tập! Điểm số: \(result.score)",
                    priority: .high
                )
                Task {
                    await rewardSystem.processSessionResult(result)
                    navigationCoordinator.showResults(result)
                }
            }
        }
        .onChange(of: viewModel.currentExerciseIndex) { index in
            accessibilityManager.announceToVoiceOver(
                "Bài tập \(index + 1) trên \(viewModel.totalExercises)",
                priority: .medium
            )
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.98, green: 0.99, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Exit button
            Button(action: {
                showingExitConfirmation = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .accessibilityLabel("Thoát luyện tập")
            .accessibilityHint("Nhấn đúp để thoát khỏi bài luyện tập hiện tại")
            .accessibilityAddTraits(.isButton)
            
            // Progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("Bài \(viewModel.currentExerciseIndex + 1)/\(viewModel.totalExercises)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.remainingTimeFormatted)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.sessionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .accessibilityLabel(accessibilityManager.getProgressAccessibilityLabel(
                        current: viewModel.currentExerciseIndex + 1,
                        total: viewModel.totalExercises,
                        type: "Tiến độ bài tập"
                    ))
            }
            
            // Score display
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.currentScore)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("điểm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Điểm số hiện tại: \(viewModel.currentScore) điểm")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - Practice Content View
    
    @ViewBuilder
    private var practiceContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise title
                if let exercise = viewModel.currentExercise {
                    Text(exercise.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Reading text display
                readingTextView
                
                // Input method selector
                inputMethodSelector
                
                // Text input area
                textInputArea
                
                // Feedback area
                if viewModel.showingFeedback {
                    feedbackView
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Reading Text View
    
    @ViewBuilder
    private var readingTextView: some View {
        VStack(spacing: 16) {
            // Text to read
            if let exercise = viewModel.currentExercise {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                        
                        Text("Đọc đoạn văn sau:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Play audio button
                        Button(action: {
                            viewModel.playExerciseAudio()
                        }) {
                            Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isRecording)
                        .accessibilityLabel(viewModel.isPlayingAudio ? "Đang phát âm thanh" : "Nghe đoạn văn mẫu")
                        .accessibilityHint(accessibilityManager.getAccessibilityHint(for: .playButton))
                        .accessibilityAddTraits(.isButton)
                    }
                    
                    // Highlighted text
                    HighlightedTextView(
                        text: exercise.targetText,
                        mistakes: viewModel.currentMistakes,
                        highlightMode: viewModel.highlightMode
                    )
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Input Method Selector
    
    @ViewBuilder
    private var inputMethodSelector: some View {
        HStack(spacing: 16) {
            ForEach(InputMethod.allCases, id: \.self) { method in
                if method.isAvailableOnDevice {
                    inputMethodButton(method)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func inputMethodButton(_ method: InputMethod) -> some View {
        Button(action: {
            viewModel.selectInputMethod(method)
        }) {
            VStack(spacing: 6) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(viewModel.selectedInputMethod == method ? .white : method == .voice ? .red : .blue)
                
                Text(method.localizedName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.selectedInputMethod == method ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.selectedInputMethod == method ? 
                          (method == .voice ? Color.red : Color.blue) : 
                          Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Text Input Area
    
    @ViewBuilder
    private var textInputArea: some View {
        VStack(spacing: 16) {
            switch viewModel.selectedInputMethod {
            case .keyboard:
                keyboardInputView
            case .handwriting:
                handwritingInputView
            case .voice:
                voiceInputView
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var keyboardInputView: some View {
        AccessibleTextInput(
            text: $viewModel.typedText,
            placeholder: "Gõ lại đoạn văn bạn vừa đọc",
            title: "Nhập văn bản",
            isMultiline: true,
            maxLength: 500
        )
        .onChange(of: viewModel.typedText) { _ in
            viewModel.processTypedText()
        }
    }
    
    @ViewBuilder
    private var handwritingInputView: some View {
        AccessibleHandwritingCanvas(
            recognizedText: $viewModel.handwrittenText,
            onTextRecognized: { text in
                viewModel.processHandwrittenText(text)
            }
        )
    }
    
    @ViewBuilder
    private var voiceInputView: some View {
        VStack(spacing: 16) {
            // Real-time feedback view
            if let exercise = viewModel.currentExercise {
                RealTimeFeedbackView(
                    targetText: exercise.targetText,
                    recognizedText: speechCoordinator.recognizedText,
                    confidence: speechCoordinator.confidence,
                    audioLevel: speechCoordinator.audioLevel,
                    isRecording: speechCoordinator.isRecording
                )
            }
            
            // Voice control buttons
            HStack(spacing: 20) {
                // Listen to target text
                Button(action: {
                    Task {
                        if let exercise = viewModel.currentExercise {
                            await speechCoordinator.speakTargetText(mode: .normal)
                        }
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Nghe")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(width: 80, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .disabled(speechCoordinator.isSpeaking || speechCoordinator.isRecording)
                
                // Record button
                Button(action: {
                    Task {
                        if speechCoordinator.isRecording {
                            let attempt = await speechCoordinator.stopRecording()
                            currentAttempt = attempt
                            showingFeedback = true
                        } else {
                            try? await speechCoordinator.startRecording()
                        }
                    }
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(speechCoordinator.isRecording ? Color.red : Color.green)
                                .frame(width: 50, height: 50)
                                .scaleEffect(speechCoordinator.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), 
                                         value: speechCoordinator.isRecording)
                            
                            Image(systemName: speechCoordinator.isRecording ? "stop.fill" : "mic.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Text(speechCoordinator.isRecording ? "Dừng" : "Đọc")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .disabled(!speechCoordinator.isAvailable)
                
                // Slow speech button
                Button(action: {
                    Task {
                        if let exercise = viewModel.currentExercise {
                            await speechCoordinator.speakTargetText(mode: .slow)
                        }
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "tortoise.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Chậm")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(width: 80, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .disabled(speechCoordinator.isSpeaking || speechCoordinator.isRecording)
            }
        }
        .onAppear {
            Task {
                if let exercise = viewModel.currentExercise {
                    try? await speechCoordinator.startReadingSession(
                        targetText: exercise.targetText,
                        mode: .practice
                    )
                }
            }
        }
        .sheet(isPresented: $showingFeedback) {
            if let attempt = currentAttempt {
                NavigationView {
                    PronunciationFeedbackView(
                        attempt: attempt,
                        onWordTap: { word in
                            speechCoordinator.speakWord(word)
                        },
                        onRetry: {
                            showingFeedback = false
                            Task {
                                try? await speechCoordinator.startRecording()
                            }
                        }
                    )
                    .navigationTitle("Kết quả")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Đóng") {
                                showingFeedback = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Feedback View
    
    @ViewBuilder
    private var feedbackView: some View {
        VStack(spacing: 16) {
            // Accuracy display
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(viewModel.accuracyColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Độ chính xác")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(viewModel.currentAccuracy * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.accuracyColor)
                }
                
                Spacer()
                
                // Score earned
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Điểm nhận được")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("+\(viewModel.lastEarnedScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Mistakes display
            if !viewModel.currentMistakes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cần cải thiện:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(viewModel.currentMistakes.prefix(4), id: \.id) { mistake in
                            mistakeItem(mistake)
                        }
                    }
                }
            }
            
            // Encouragement message
            Text(viewModel.encouragementMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func mistakeItem(_ mistake: TextMistake) -> some View {
        HStack(spacing: 8) {
            Image(systemName: mistake.mistakeType.icon)
                .font(.caption)
                .foregroundColor(mistake.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mistake.expectedWord)
                    .font(.caption)
                    .fontWeight(.medium)
                    .strikethrough()
                    .foregroundColor(.red)
                
                if let actualWord = mistake.actualWord {
                    Text(actualWord)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Controls View
    
    @ViewBuilder
    private var controlsView: some View {
        HStack(spacing: 16) {
            // Skip button
            Button(action: {
                viewModel.skipCurrentExercise()
            }) {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Bỏ qua")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Submit/Next button
            Button(action: {
                if viewModel.showingFeedback {
                    viewModel.nextExercise()
                } else {
                    viewModel.submitAnswer()
                }
            }) {
                HStack {
                    Text(viewModel.showingFeedback ? "Tiếp theo" : "Kiểm tra")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(viewModel.canSubmit ? Color.blue : Color.gray)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.canSubmit)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
struct ReadingPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingPracticeView(
            config: PracticeSessionConfig(
                difficulty: .grade2,
                category: .story,
                mode: .normal
            )
        )
        .environmentObject(NavigationCoordinator())
        .environmentObject(RewardSystem(progressTracker: ProgressTrackingFactory.shared.getProgressTracker()))
    }
}