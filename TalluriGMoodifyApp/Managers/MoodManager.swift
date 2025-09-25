//
//  MoodManager.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation
import CoreMotion
import UIKit

class MoodManager: ObservableObject {
    @Published var selectedMood: MoodType = .happy
    @Published var currentPlaylist: [MediaItem] = []
    @Published var favoriteItems: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastVoiceSearchQuery: String?
    @Published var voiceSearchDetectedMood: MoodType?
    
    private let youtubeService = YouTubeAPIService()
    private var motionManager = CMMotionManager()
    private var isShakeDetectionActive = false
    
    init() {
        loadFavorites()
        setupShakeDetection()
       
        Task {
            await selectMoodAsync(.happy)
        }
    }
    
    func selectMood(_ mood: MoodType) {
        print("👆 User selected mood: \(mood.rawValue)")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedMood = mood
            errorMessage = nil
            if voiceSearchDetectedMood == mood {
                print("🎤 Voice search successfully switched to \(mood.rawValue)")
            }
        }
        Task {
            await fetchSongsForMood(mood)
        }
        
        UIImpactFeedbackGenerator.mediumImpact()
    }
    @MainActor
    private func selectMoodAsync(_ mood: MoodType) async {
        print("🎵 Selecting mood async: \(mood.rawValue)")
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedMood = mood
            errorMessage = nil
        }
        
        await fetchSongsForMood(mood)
        UIImpactFeedbackGenerator.mediumImpact()
    }
    @MainActor
    func searchMusic(query: String) async {
        print("🔍 Voice search for: \(query)")
        
        lastVoiceSearchQuery = query
        if let detectedMood = detectMoodFromVoiceInput(query) {
            print("🎯 Detected mood from voice: \(detectedMood.rawValue)")
            voiceSearchDetectedMood = detectedMood
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                selectedMood = detectedMood
                errorMessage = "🎤 Voice detected: \(detectedMood.rawValue) mood"
            }
            
            await fetchSongsForMood(detectedMood)
            
            UIImpactFeedbackGenerator.heavyImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.voiceSearchDetectedMood = nil
                self.lastVoiceSearchQuery = nil
                if self.errorMessage?.contains("Voice detected") == true {
                    self.errorMessage = nil
                }
            }
            
            return
        }
        
        isLoading = true
        voiceSearchDetectedMood = nil
        
        do {
            let songs = try await youtubeService.searchMusic(query: query)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPlaylist = songs
                isLoading = false
                errorMessage = "🔍 Found \(songs.count) songs for '\(query)'"
            }
            
            print("✅ Voice search found \(songs.count) songs")
           
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.errorMessage?.contains("Found") == true {
                    self.errorMessage = nil
                }
            }
            
        } catch {
            print("❌ Voice search error: \(error)")
            
            withAnimation {
                isLoading = false
                errorMessage = "Voice search failed. Showing \(selectedMood.rawValue) mood playlist."
            }
        }
    }
    private func detectMoodFromVoiceInput(_ query: String) -> MoodType? {
        let lowercasedQuery = query.lowercased()
        let moodKeywords: [MoodType: [(String, Int)]] = [
            .happy: [
                ("happy", 10), ("cheerful", 8), ("joyful", 8), ("upbeat", 9),
                ("feel good", 9), ("positive", 7), ("dance", 6), ("party", 8),
                ("fun", 7), ("celebration", 6), ("joy", 8), ("good vibes", 8),
                ("optimistic", 6), ("bright", 5), ("sunny", 6), ("lively", 7)
            ],
            .sad: [
                ("sad", 10), ("melancholy", 9), ("emotional", 7), ("depressing", 8),
                ("heartbreak", 9), ("cry", 8), ("tears", 8), ("lonely", 8),
                ("blue", 6), ("down", 6), ("grief", 8), ("sorrow", 8),
                ("ballad", 7), ("slow songs", 8), ("breakup", 9), ("missing", 7)
            ],
            .energetic: [
                ("energetic", 10), ("pump up", 9), ("workout", 9), ("exercise", 8),
                ("gym", 8), ("running", 7), ("high energy", 9), ("motivated", 7),
                ("powerful", 7), ("intense", 8), ("adrenaline", 8), ("cardio", 7),
                ("rock", 6), ("metal", 7), ("electronic", 6), ("edm", 8)
            ],
            .chill: [
                ("chill", 10), ("relax", 9), ("calm", 8), ("peaceful", 8),
                ("zen", 7), ("meditation", 8), ("lo-fi", 9), ("ambient", 8),
                ("soft", 6), ("quiet", 6), ("soothing", 8), ("laid back", 8),
                ("study music", 9), ("background", 6), ("cafe", 7), ("mellow", 7)
            ],
            .angry: [
                ("angry", 10), ("rage", 9), ("aggressive", 9), ("mad", 8),
                ("furious", 8), ("metal", 8), ("hardcore", 8), ("punk", 7),
                ("scream", 7), ("heavy", 7), ("brutal", 8), ("fierce", 7),
                ("hard rock", 8), ("alternative", 6), ("grunge", 7)
            ],
            .romantic: [
                ("romantic", 10), ("love", 9), ("romance", 9), ("valentine", 8),
                ("date night", 8), ("intimate", 8), ("r&b", 7), ("soul", 7),
                ("smooth", 7), ("sensual", 8), ("passion", 7), ("love songs", 9),
                ("couples", 7), ("wedding", 7), ("anniversary", 7)
            ]
        ]
        var moodScores: [MoodType: Int] = [:]
        
        for (mood, keywordWeights) in moodKeywords {
            for (keyword, weight) in keywordWeights {
                if lowercasedQuery.contains(keyword) {
                    moodScores[mood, default: 0] += weight
                    print("🎯 Found keyword '\(keyword)' for \(mood.rawValue) (weight: \(weight))")
                }
            }
        }
        if let bestMood = moodScores.max(by: { $0.value < $1.value }),
           bestMood.value >= 5 {
            print("🎯 Best mood match: \(bestMood.key.rawValue) (score: \(bestMood.value))")
            return bestMood.key
        }
        for mood in MoodType.allCases {
            if lowercasedQuery.contains(mood.rawValue.lowercased()) {
                print("🎯 Found direct mood match: \(mood.rawValue)")
                return mood
            }
        }
        
        print("❓ No strong mood detected in query: \(query)")
        return nil
    }
    
    @MainActor
    func fetchSongsForMood(_ mood: MoodType) async {
        print("🔍 Fetching songs for mood: \(mood.rawValue)")
        
        isLoading = true
        
        do {
            let searchQuery = createSearchQuery(for: mood)
            print("🔍 Search query: \(searchQuery)")
            
            let songs = try await youtubeService.searchMusic(query: searchQuery)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPlaylist = songs
                isLoading = false
                
                if voiceSearchDetectedMood == mood {
                    errorMessage = "🎤 Voice search: Found \(songs.count) \(mood.rawValue) songs"
                } else {
                    errorMessage = nil
                }
            }
            
            print("✅ Found \(songs.count) songs for \(mood.rawValue)")
            
        } catch {
            print("❌ Error fetching songs: \(error)")
            
            withAnimation {
                isLoading = false
                
                let mockPlaylist = createMockPlaylist(for: mood)
                currentPlaylist = mockPlaylist
                
                switch error {
                case APIError.unauthorized:
                    errorMessage = "YouTube API key issue. Using sample songs."
                case APIError.quotaExceeded:
                    errorMessage = "API quota exceeded. Using sample songs."
                case APIError.noData:
                    errorMessage = "No songs found. Using sample songs."
                default:
                    errorMessage = "Network error. Using sample songs."
                }
            }
        }
    }
  
    private func createSearchQuery(for mood: MoodType) -> String {
        switch mood {
        case .happy:
            return "happy upbeat pop music feel good songs 2024"
        case .sad:
            return "sad emotional ballad music heartbreak songs"
        case .energetic:
            return "energetic workout pump up music high energy 2024"
        case .chill:
            return "chill lo-fi relaxing music ambient calm vibes"
        case .angry:
            return "rock metal aggressive music angry songs heavy"
        case .romantic:
            return "romantic love songs R&B soul music intimate"
        }
    }
    var isVoiceSearchActive: Bool {
        return voiceSearchDetectedMood != nil || lastVoiceSearchQuery != nil
    }
    
    var voiceSearchFeedback: String? {
        if let mood = voiceSearchDetectedMood {
            return "🎤 Voice detected: \(mood.rawValue)"
        }
        if let query = lastVoiceSearchQuery {
            return "🔍 Searching: \(query)"
        }
        return nil
    }
    func shuffleCurrentPlaylist() {
        print("🎲 Shuffling current playlist")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPlaylist.shuffle()
        }
        
        UIImpactFeedbackGenerator.mediumImpact()
    }
    
    func shuffleToRandomMood() {
        print("🎲 Shuffling to random mood")
        
        let randomMood = MoodType.allCases.randomElement() ?? .happy
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            selectMood(randomMood)
        }
        
        UIImpactFeedbackGenerator.heavyImpact()
    }
    func setupShakeDetection() {
        guard !isShakeDetectionActive else { return }
        
        #if targetEnvironment(simulator)
        print("📱 Shake detection disabled in simulator")
        return
        #else
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ Accelerometer not available")
            return
        }
        
        isShakeDetectionActive = true
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let acceleration = data?.acceleration else { return }
            
            let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
            
            if magnitude > Constants.shakeThreshold {
                self?.handleShakeDetected()
            }
        }
        print("📱 Shake detection activated")
        #endif
    }
    
    func startShakeDetection() {
        setupShakeDetection()
    }
    
    private func handleShakeDetected() {
        print("📱 Shake detected!")
        shuffleToRandomMood()
        
        motionManager.stopAccelerometerUpdates()
        isShakeDetectionActive = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupShakeDetection()
        }
    }
    private func createMockPlaylist(for mood: MoodType) -> [MediaItem] {
        let moodSongs: [String] = {
            switch mood {
            case .happy:
                return ["Happy - Pharrell Williams", "Can't Stop the Feeling - Justin Timberlake", "Good as Hell - Lizzo", "Uptown Funk - Bruno Mars", "Shake It Off - Taylor Swift"]
            case .sad:
                return ["Someone Like You - Adele", "Hurt - Johnny Cash", "Mad World - Gary Jules", "Black - Pearl Jam", "Tears in Heaven - Eric Clapton"]
            case .energetic:
                return ["Eye of the Tiger - Survivor", "Don't Stop Me Now - Queen", "Pump It - Black Eyed Peas", "Thunder - Imagine Dragons", "Stronger - Kanye West"]
            case .chill:
                return ["Weightless - Marconi Union", "Clair de Lune - Debussy", "Aqueous Transmission - Incubus", "Porcelain - Moby", "Teardrop - Massive Attack"]
            case .angry:
                return ["Break Stuff - Limp Bizkit", "Chop Suey! - System of a Down", "Bodies - Drowning Pool", "Killing in the Name - Rage Against the Machine", "Indestructible - Disturbed"]
            case .romantic:
                return ["All of Me - John Legend", "Thinking Out Loud - Ed Sheeran", "Perfect - Ed Sheeran", "At Last - Etta James", "Make You Feel My Love - Adele"]
            }
        }()
        
        return moodSongs.enumerated().map { index, title in
            let components = title.components(separatedBy: " - ")
            let songTitle = components.first ?? title
            let artist = components.count > 1 ? components[1] : "Unknown Artist"
            
            return MediaItem(
                id: "\(mood.rawValue)_\(index)",
                title: songTitle,
                artist: artist,
                thumbnailURL: "",
                videoURL: "https://www.youtube.com/watch?v=sample\(index)"
            )
        }
    }
    func toggleFavorite(_ item: MediaItem) {
        print("❤️ Toggling favorite for: \(item.title)")
        
        if favoriteItems.contains(where: { $0.id == item.id }) {
            favoriteItems.removeAll { $0.id == item.id }
            print("💔 Removed from favorites")
        } else {
            favoriteItems.append(item)
            print("💖 Added to favorites")
        }
        
        saveFavorites()
        UIImpactFeedbackGenerator.lightImpact()
    }
    
    func isFavorite(_ item: MediaItem) -> Bool {
        favoriteItems.contains { $0.id == item.id }
    }
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteItems) {
            UserDefaults.standard.set(encoded, forKey: Constants.favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: Constants.favoritesKey),
           let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) {
            favoriteItems = decoded
        }
    }
}
