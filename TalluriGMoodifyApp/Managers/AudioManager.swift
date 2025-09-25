//
//  AudioManager.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation
import AVFoundation
import AudioToolbox
import MusicKit

class AudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentItem: MediaItem?
    @Published var playbackProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isAppleMusicSubscriber = false
    @Published var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private let appleMusicPlayer = ApplicationMusicPlayer.shared
    
    override init() {
        super.init()
        setupAudioSession()
        checkMusicKitAuthorization()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            errorMessage = "Audio setup failed"
        }
    }
    private func checkMusicKitAuthorization() {
        Task {
            let status = await MusicAuthorization.currentStatus
            
            await MainActor.run {
                self.musicAuthorizationStatus = status
                print("🎵 MusicKit authorization status: \(status)")
                
                if status == .authorized {
                    self.checkAppleMusicSubscription()
                }
            }
        }
    }
    
    func requestMusicKitAuthorization() async {
        let status = await MusicAuthorization.request()
        
        await MainActor.run {
            self.musicAuthorizationStatus = status
            print("🎵 MusicKit authorization requested: \(status)")
            
            if status == .authorized {
                self.checkAppleMusicSubscription()
            } else {
                self.errorMessage = "Apple Music access denied. Using preview mode."
            }
        }
    }
    
    private func checkAppleMusicSubscription() {
        Task {
            do {
                let subscription = try await MusicSubscription.current
                let hasSubscription = subscription.canPlayCatalogContent
                
                await MainActor.run {
                    self.isAppleMusicSubscriber = hasSubscription
                    print("🎵 Apple Music subscriber: \(hasSubscription)")
                    
                    if !hasSubscription {
                        print("ℹ️ User doesn't have Apple Music subscription - using preview mode")
                    }
                }
            } catch {
                print("❌ Error checking subscription: \(error)")
                await MainActor.run {
                    self.isAppleMusicSubscriber = false
                }
            }
        }
    }
    func playItem(_ item: MediaItem) {
        print("🎵 Playing: \(item.title)")
        
        if currentItem?.id == item.id {
            
            if isPlaying {
                pausePlayback()
            } else {
                resumePlayback()
            }
        } else {
            
            stopPlayback()
            currentItem = item
           
            if musicAuthorizationStatus != .authorized {
                Task {
                    await requestMusicKitAuthorization()
                    await MainActor.run {
                        if self.musicAuthorizationStatus == .authorized {
                            self.startPlayback(item)
                        } else {
                            self.playPreviewFallback(item)
                        }
                    }
                }
            } else {
                startPlayback(item)
            }
        }
        
        UIImpactFeedbackGenerator.lightImpact()
    }
    
    private func startPlayback(_ item: MediaItem) {
        if isAppleMusicSubscriber {
            playWithMusicKit(item)
        } else {
            playPreviewFallback(item)
        }
    }
    private func playWithMusicKit(_ item: MediaItem) {
        print("🎵 Attempting MusicKit playback for: \(item.title)")
        
        Task {
            do {
                await MainActor.run {
                    self.isLoading = true
                    self.errorMessage = nil
                }
               
                var searchRequest = MusicCatalogSearchRequest(
                    term: "\(item.title) \(item.artist)",
                    types: [Song.self]
                )
                searchRequest.limit = 1
                
                let searchResponse = try await searchRequest.response()
                
                guard let song = searchResponse.songs.first else {
                    print("❌ Song not found in Apple Music catalog")
                    await MainActor.run {
                        self.playPreviewFallback(item)
                    }
                    return
                }
                appleMusicPlayer.queue = ApplicationMusicPlayer.Queue(for: [song])
                
                try await appleMusicPlayer.play()
                
                await MainActor.run {
                    self.isPlaying = true
                    self.isLoading = false
                    self.startMusicKitTimer()
                }
                
                print("▶️ Started MusicKit playback: \(item.title)")
                
            } catch {
                print("❌ MusicKit playback error: \(error)")
                await MainActor.run {
                    self.playPreviewFallback(item)
                }
            }
        }
    }
    private func playPreviewFallback(_ item: MediaItem) {
        print("🎵 Using preview mode for: \(item.title)")
        
        isLoading = true
        errorMessage = "Playing 30-second preview"
        
        playMockPreview(item)
    }
    
    private func playMockPreview(_ item: MediaItem) {
       
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                self.isPlaying = true
                self.isLoading = false
                self.playbackProgress = 0.0
            }
            
            self.startMockPreviewTimer()
            SystemSoundID.playFileNamed("preview_sound", withExtension: "mp3")
            
            print("▶️ Started mock preview: \(item.title)")
        }
    }
    
    private func startMockPreviewTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard self.isPlaying else { return }
            
            self.playbackProgress += 0.5 / 30.0
            if self.playbackProgress >= 1.0 {
                self.stopPlayback()
            }
        }
    }
    
    private func startMusicKitTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard self.isPlaying else { return }
            
            Task {
                do {
                    if let currentEntry = try await self.appleMusicPlayer.queue.currentEntry,
                       let song = currentEntry.item as? Song {
                        let playbackTime = try await self.appleMusicPlayer.playbackTime
                        let duration = song.duration ?? 180
                        
                        await MainActor.run {
                            if duration > 0 {
                                self.playbackProgress = playbackTime / duration
                            }
                        }
                    }
                } catch {
                    print("❌ Error updating playback progress: \(error)")
                }
            }
        }
    }
    func pausePlayback() {
        print("⏸️ Pausing playback")
        
        withAnimation {
            isPlaying = false
        }
        
        if isAppleMusicSubscriber && musicAuthorizationStatus == .authorized {
            appleMusicPlayer.pause()
        }
        
        audioPlayer?.pause()
        stopPlaybackTimer()
    }
    
    func resumePlayback() {
        print("▶️ Resuming playback")
        
        withAnimation {
            isPlaying = true
        }
        
        if isAppleMusicSubscriber && musicAuthorizationStatus == .authorized {
            Task {
                try? await appleMusicPlayer.play()
            }
            startMusicKitTimer()
        } else {
            audioPlayer?.play()
            startMockPreviewTimer()
        }
    }
    
    func stopPlayback() {
        print("⏹️ Stopping playback")
        
        withAnimation {
            isPlaying = false
            currentItem = nil
            playbackProgress = 0.0
            isLoading = false
        }
        
        appleMusicPlayer.stop()
        audioPlayer?.stop()
        audioPlayer = nil
        stopPlaybackTimer()
    }
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    var formattedCurrentTime: String {
        if let durationString = currentItem?.duration {
            let duration = parseDurationString(durationString)
            return formatTime(playbackProgress * duration)
        }
        return formatTime(playbackProgress * 180)
    }
    
    var formattedDuration: String {
        return currentItem?.duration ?? "3:00"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func parseDurationString(_ duration: String) -> TimeInterval {
        let components = duration.split(separator: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return 180.0
        }
        return minutes * 60 + seconds
    }
    
    deinit {
        stopPlaybackTimer()
        audioPlayer?.stop()
        appleMusicPlayer.stop()
    }
}
extension String {
    var timeInterval: TimeInterval {
        let components = self.split(separator: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return 30.0
        }
        return minutes * 60 + seconds
    }
}
extension SystemSoundID {
    static func playFileNamed(_ fileName: String, withExtension fileExtension: String) {
        if let bundlePath = Bundle.main.path(forResource: fileName, ofType: fileExtension) {
            let url = URL(fileURLWithPath: bundlePath)
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
        } else {
            
            AudioServicesPlaySystemSound(1016) 
        }
    }
}
