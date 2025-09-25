//
//  FavoritesView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    if moodManager.favoriteItems.isEmpty {
                        VStack(spacing: adaptiveSpacing(for: geometry.size)) {
                            Spacer()
                            
                            Image(systemName: "heart.slash")
                                .font(.system(size: adaptiveFontSize(base: 60, for: geometry.size)))
                                .foregroundColor(.gray)
                            
                            Text("No Favorites Yet")
                                .font(.system(size: adaptiveFontSize(base: 22, for: geometry.size), weight: .semibold))
                            
                            Text("Add songs to your favorites by tapping the heart icon")
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size)))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Spacer()
                            TabNavigationButton(
                                title: "Explore Music",
                                icon: "heart.fill",
                                targetTab: 0
                            )
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else
                    {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(moodManager.favoriteItems.count) Favorite\(moodManager.favoriteItems.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            List {
                                ForEach(moodManager.favoriteItems) { item in
                                    MediaItemRow(item: item)
                                        .environmentObject(audioManager)
                                        .environmentObject(moodManager)
                                }
                                .onDelete(perform: deleteFavorites)
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }
                .navigationTitle("Favorites")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarItems(
                    trailing: moodManager.favoriteItems.isEmpty ? nil : EditButton()
                )
            }
        }
    }
    
    private func deleteFavorites(offsets: IndexSet) {
        for index in offsets {
            let item = moodManager.favoriteItems[index]
            moodManager.toggleFavorite(item)
        }
    }
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        let baseSpacing: CGFloat = 20
        let screenHeight = size.height
        
        if screenHeight < 700 {
            return baseSpacing * 0.8
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
}
struct TabNavigationButton: View {
    let title: String
    let icon: String
    let targetTab: Int
    
    var body: some View {
        Button(action: {
            switchToTab(targetTab)
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                             startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(25)
        }
    }
    
    private func switchToTab(_ index: Int) {
        NotificationCenter.default.post(
            name: Notification.Name("SwitchToTab"),
            object: nil,
            userInfo: ["tabIndex": index]
        )
        UIImpactFeedbackGenerator.mediumImpact()
    }
}
