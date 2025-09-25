//
//  VoiceSearchView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceSearchView: View {
    @State private var isListening = false
    @State private var recognizedText = ""
    @State private var detectedMood: MoodType?
    @EnvironmentObject var moodManager: MoodManager
    @StateObject private var speechRecognizer = SpeechRecognitionManager()
    @State private var shouldNavigateToPlaylist = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: adaptiveSpacing(for: geometry.size)) {
             
                    VStack(spacing: 10) {
                        Text("🎤")
                            .font(.system(size: adaptiveFontSize(base: 50, for: geometry.size)))
                        
                        Text("Voice Search")
                            .font(.system(size: adaptiveFontSize(base: 28, for: geometry.size), weight: .bold))
                            .foregroundStyle(
                                LinearGradient(gradient: Gradient(colors: [.blue, .cyan]),
                                             startPoint: .leading, endPoint: .trailing)
                            )
                        
                        Text("Say your mood or song preference")
                            .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size)))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                 
                    if let mood = detectedMood {
                        VStack(spacing: 10) {
                            HStack {
                                Text(mood.emoji)
                                    .font(.title)
                                Text("Detected: \(mood.rawValue)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(mood.color)
                      
                            Button(action: {
                                shouldNavigateToPlaylist = true
                            }) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                    Text("Explore \(mood.rawValue) Music")
                                }
                                .foregroundColor(.white)
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                                .padding()
                                .background(mood.color)
                                .cornerRadius(25)
                            }
                        }
                        .padding()
                        .background(mood.color.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
               
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                            .frame(width: adaptiveCircleSize(for: geometry.size), height: adaptiveCircleSize(for: geometry.size))
                            .scaleEffect(isListening ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: adaptiveFontSize(base: 50, for: geometry.size)))
                            .foregroundColor(isListening ? .red : .gray)
                    }
                    .onTapGesture {
                        toggleListening()
                    }
                    
                    Text(isListening ? "Listening..." : "Tap microphone to speak")
                        .font(.system(size: adaptiveFontSize(base: 18, for: geometry.size), weight: .medium))
                        .foregroundColor(isListening ? .red : .primary)
                 
                    VStack(spacing: 8) {
                        Text("Try saying:")
                            .font(.system(size: adaptiveFontSize(base: 14, for: geometry.size)))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("• \"Happy music\" or \"Sad songs\"")
                            Text("• \"Energetic playlist\" or \"Chill vibes\"")
                            Text("• \"Rock music\" or \"Love songs\"")
                        }
                        .font(.system(size: adaptiveFontSize(base: 12, for: geometry.size)))
                        .foregroundColor(.secondary)
                    }
                    
                    if !recognizedText.isEmpty {
                        VStack(spacing: 10) {
                            Text("You said:")
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text("\"\(recognizedText)\"")
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .medium))
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                
                    VStack(spacing: 15) {
                        Button(isListening ? "Stop Listening" : "Start Voice Search") {
                            toggleListening()
                        }
                        .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isListening ? Color.red : Color.blue)
                        .cornerRadius(25)
                        
                        if !recognizedText.isEmpty && detectedMood == nil {
                            Button("Search for \"\(recognizedText.truncated(toLength: 30))\"") {
                                processVoiceSearch()
                            }
                            .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 30)
                }
                .navigationBarHidden(true)
            
                .background(
                    NavigationLink(
                        destination: PlaylistView(),
                        isActive: $shouldNavigateToPlaylist
                    ) { EmptyView() }
                )
                .onAppear {
                    speechRecognizer.requestAuthorization()
                }
                .onChange(of: speechRecognizer.recognizedText) { text in
                    recognizedText = text
                    if !text.isEmpty && !isListening {
                        processVoiceSearch()
                    }
                }
                .onChange(of: speechRecognizer.isListening) { listening in
                    isListening = listening
                }
                .alert("Permission Required", isPresented: .constant(speechRecognizer.authorizationStatus == .denied)) {
                    Button("Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    Button("Cancel") {}
                } message: {
                    Text("Please enable microphone access in Settings to use voice search.")
                }
            }
        }
    }
    
    private func toggleListening() {
        if isListening {
            speechRecognizer.stopListening()
        } else {
            speechRecognizer.startListening()
        }
    }
    private func processVoiceSearch() {
        let lowercasedText = recognizedText.lowercased()
   
        if let detectedMoodType = detectMoodFromVoiceInput(lowercasedText) {
            print("🎯 Voice detected mood: \(detectedMoodType.rawValue)")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                detectedMood = detectedMoodType
            }
            moodManager.selectMood(detectedMoodType)
            UIImpactFeedbackGenerator.heavyImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                shouldNavigateToPlaylist = true
            }
            
            return
        }
        Task {
            await moodManager.searchMusic(query: recognizedText)
        }
        
        UIImpactFeedbackGenerator.lightImpact()
    }
    private func detectMoodFromVoiceInput(_ query: String) -> MoodType? {
        let lowercasedQuery = query.lowercased()
        let moodKeywords: [MoodType: [String]] = [
            .happy: [
                "happy", "cheerful", "joyful", "upbeat", "feel good", "positive",
                "energetic music", "dance", "party", "fun", "celebration", "joy",
                "good vibes", "optimistic", "bright", "sunny", "lively", "peppy"
            ],
            .sad: [
                "sad", "melancholy", "emotional", "depressing", "heartbreak",
                "cry", "tears", "lonely", "blue", "down", "grief", "sorrow",
                "ballad", "slow songs", "breakup", "lost love", "missing", "somber"
            ],
            .energetic: [
                "energetic", "pump up", "workout", "exercise", "gym", "running",
                "high energy", "motivated", "powerful", "intense", "adrenaline",
                "rock", "metal", "electronic", "edm", "bass", "beats", "cardio"
            ],
            .chill: [
                "chill", "relax", "calm", "peaceful", "zen", "meditation",
                "lo-fi", "ambient", "soft", "quiet", "soothing", "laid back",
                "study music", "background", "cafe", "jazz", "acoustic", "mellow"
            ],
            .angry: [
                "angry", "rage", "aggressive", "mad", "furious", "metal",
                "hardcore", "punk", "scream", "heavy", "brutal", "fierce",
                "rock", "hard rock", "alternative", "grunge", "intense"
            ],
            .romantic: [
                "romantic", "love", "romance", "valentine", "date night",
                "intimate", "r&b", "soul", "smooth", "sensual", "passion",
                "love songs", "couples", "wedding", "anniversary", "sexy"
            ]
        ]
        var moodScores: [MoodType: Int] = [:]
        
        for (mood, keywords) in moodKeywords {
            for keyword in keywords {
                if lowercasedQuery.contains(keyword) {
                    moodScores[mood, default: 0] += 1
                    print("🎯 Found mood keyword '\(keyword)' for mood \(mood.rawValue)")
                }
            }
        }
        if let bestMood = moodScores.max(by: { $0.value < $1.value }) {
            if bestMood.value > 0 {
                print("🎯 Best mood match: \(bestMood.key.rawValue) (score: \(bestMood.value))")
                return bestMood.key
            }
        }
        for mood in MoodType.allCases {
            if lowercasedQuery.contains(mood.rawValue.lowercased()) {
                print("🎯 Found direct mood match: \(mood.rawValue)")
                return mood
            }
        }
        
        print("❓ No mood detected in query: \(query)")
        return nil
    }
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        let baseSpacing: CGFloat = 20
        let screenHeight = size.height
        
        if screenHeight < 700 {
            return baseSpacing * 0.7
        } else if screenHeight > 900 {
            return baseSpacing * 1.2
        }
        return baseSpacing
    }
    
    private func adaptiveFontSize(base: CGFloat, for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        let scaleFactor: CGFloat
        
        if screenHeight < 700 {
            scaleFactor = 0.85
        } else if screenHeight > 900 {
            scaleFactor = 1.1
        } else {
            scaleFactor = 1.0
        }
        
        return base * scaleFactor
    }
    
    private func adaptiveCircleSize(for size: CGSize) -> CGFloat {
        let baseSize: CGFloat = 150
        let screenWidth = size.width
        
        if screenWidth < 400 {
            return baseSize * 0.8
        } else if screenWidth > 450 {
            return baseSize * 1.1
        }
        return baseSize
    }
}
class SpeechRecognitionManager: ObservableObject {
    @Published var recognizedText = ""
    @Published var isListening = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                print("🎤 Speech authorization status: \(status.rawValue)")
            }
        }
    }
    
    func startListening() {
        guard authorizationStatus == .authorized else {
            print("❌ Speech recognition not authorized")
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            return
        }
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }
        
        isListening = true
        recognizedText = ""
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("🎤 Started listening...")
        } catch {
            print("❌ Audio engine couldn't start: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self?.stopListening()
            }
        }
    }
    
    func stopListening() {
        print("🎤 Stopping listening...")
        
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
}
