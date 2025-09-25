//
//  TalluriGMoodifyAppApp.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

@main
struct TalluriGMoodifyAppApp: App {
    @StateObject private var moodManager = MoodManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var locationManager = LocationManager()
    @State private var showWelcome = true 
    
    var body: some Scene {
        WindowGroup {
            if showWelcome {
                WelcomeView(showWelcome: $showWelcome)
                    .environmentObject(moodManager)
                    .environmentObject(audioManager)
                    .environmentObject(favoritesManager)
            } else {
                ContentView()
                    .environmentObject(moodManager)
                    .environmentObject(audioManager)
                    .environmentObject(favoritesManager)
                    .environmentObject(locationManager)
            }
        }
    }
}
