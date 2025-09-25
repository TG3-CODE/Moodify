//
//  PlaylistView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingShuffleOptions = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    if moodManager.isVoiceSearchActive {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.blue)
                                Text(moodManager.voiceSearchFeedback ?? "Voice Search Active")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            if let mood = moodManager.voiceSearchDetectedMood {
                                HStack {
                                    Text(mood.emoji)
                                        .font(.title2)
                                    Text("Switched to \(mood.rawValue) playlist")
                                        .font(.subheadline)
                                        .foregroundColor(mood.color)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                                         startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.slide.combined(with: .opacity))
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Mood")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Text(moodManager.selectedMood.emoji)
                                    .font(.title2)
                                    .scaleEffect(moodManager.voiceSearchDetectedMood != nil ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: moodManager.voiceSearchDetectedMood)
                                
                                Text(moodManager.selectedMood.rawValue.capitalized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(moodManager.selectedMood.color)
                            }
                            HStack {
                                Text("\(moodManager.currentPlaylist.count) songs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if moodManager.voiceSearchDetectedMood != nil {
                                    Text("• Voice detected")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Spacer()
                        Button(action: {
                            showingShuffleOptions = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "shuffle")
                                Text("Shuffle")
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(15)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(moodManager.selectedMood.color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(moodManager.selectedMood.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    if let errorMessage = moodManager.errorMessage {
                        HStack {
                            Image(systemName: getErrorIcon(for: errorMessage))
                                .foregroundColor(getErrorColor(for: errorMessage))
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(getErrorColor(for: errorMessage))
                        }
                        .padding()
                        .background(getErrorColor(for: errorMessage).opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .transition(.slide.combined(with: .opacity))
                    }
                    if moodManager.isLoading {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            VStack(spacing: 8) {
                                Text("Loading your \(moodManager.selectedMood.rawValue) playlist...")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                if moodManager.voiceSearchDetectedMood != nil {
                                    Text("🎤 Processing voice command...")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        Spacer()
                    } else if moodManager.currentPlaylist.isEmpty {
                        EmptyPlaylistView()
                    } else {
                        List(moodManager.currentPlaylist) { item in
                            MediaItemRow(item: item)
                                .environmentObject(audioManager)
                                .environmentObject(moodManager)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Your Playlist")
                .navigationBarTitleDisplayMode(.inline)
                .actionSheet(isPresented: $showingShuffleOptions) {
                    ActionSheet(
                        title: Text("Shuffle Options"),
                        message: Text("Choose how you want to shuffle"),
                        buttons: [
                            .default(Text("🎵 Shuffle Current Playlist")) {
                                moodManager.shuffleCurrentPlaylist()
                            },
                            .default(Text("🎭 Random Mood")) {
                                moodManager.shuffleToRandomMood()
                            },
                            .default(Text("📱 Shake Phone (Always Active)")) {
                                
                            },
                            .cancel()
                        ]
                    )
                }
            }
        }
    }
    private func getErrorIcon(for message: String) -> String {
        if message.contains("Voice detected") || message.contains("🎤") {
            return "mic.fill"
        } else if message.contains("Found") || message.contains("🔍") {
            return "magnifyingglass"
        } else if message.contains("sample") || message.contains("Using") {
            return "wifi.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    private func getErrorColor(for message: String) -> Color {
        if message.contains("Voice detected") || message.contains("🎤") {
            return .blue
        } else if message.contains("Found") || message.contains("✅") {
            return .green
        } else if message.contains("sample") || message.contains("Using") {
            return .orange
        } else {
            return .red
        }
    }
}
struct EmptyPlaylistView: View {
    @EnvironmentObject var moodManager: MoodManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: moodManager.isVoiceSearchActive ? "mic.slash" : "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(moodManager.isVoiceSearchActive ? "Voice search found no results" : "No songs found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if moodManager.isVoiceSearchActive {
                Text("Try saying a different mood or music preference")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Try selecting a different mood or check your internet connection")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            VStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        await moodManager.fetchSongsForMood(moodManager.selectedMood)
                    }
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if moodManager.isVoiceSearchActive {
                    Button("Back to \(moodManager.selectedMood.rawValue) Mood") {
                        moodManager.voiceSearchDetectedMood = nil
                        moodManager.lastVoiceSearchQuery = nil
                        
                        Task {
                            await moodManager.fetchSongsForMood(moodManager.selectedMood)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
    }
}
struct MediaItemRow: View {
    let item: MediaItem
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var moodManager: MoodManager
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 45)
            .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(item.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(item.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if moodManager.voiceSearchDetectedMood != nil {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if audioManager.currentItem?.id == item.id && audioManager.isPlaying {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("Playing")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            
            Spacer()
            VStack(spacing: 8) {
                Button(action: {
                    print("🎯 Favorite button tapped for: \(item.title)")
                    moodManager.toggleFavorite(item)
                }) {
                    Image(systemName: moodManager.isFavorite(item) ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    print("🎯 Play button tapped for: \(item.title)")
                    audioManager.playItem(item)
                }) {
                    Image(systemName: audioManager.currentItem?.id == item.id && audioManager.isPlaying ?
                          "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
