//
//  ContentView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var selectedTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
                MoodSelectionView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Moods")
                    }
                    .tag(0)
                
                PlaylistView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Playlist")
                    }
                    .tag(1)
                
                VoiceSearchTabView()
                    .tabItem {
                        Image(systemName: "mic.fill")
                        Text("Voice")
                    }
                    .tag(2)
                FavoritesView()
                    .tabItem {
                        Image(systemName: "heart")
                        Text("Favorites")
                    }
                    .tag(3)
               
                ConcertMapView()
                    .tabItem {
                        Image(systemName: "map.fill")
                        Text("Concerts")
                    }
                    .tag(4)
            }
            .accentColor(.purple)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToTab"))) { notification in
                if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tabIndex
                    }
                    print("🔄 Switched to tab: \(tabIndex)")
                }
            }
        }
    }
}
struct VoiceSearchTabView: View {
    @EnvironmentObject var moodManager: MoodManager
    
    var body: some View {
        VoiceSearchView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MoodManager())
            .environmentObject(AudioManager())
            .environmentObject(FavoritesManager())
            .previewDevice("iPhone 15 Pro")
        
        ContentView()
            .environmentObject(MoodManager())
            .environmentObject(AudioManager())
            .environmentObject(FavoritesManager())
            .previewDevice("iPhone 16 Pro")
    }
}
