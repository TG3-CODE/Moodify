//
//  FavoritesManager.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation

class FavoritesManager: ObservableObject {
    @Published var favoriteItems: [MediaItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = Constants.favoritesKey
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(_ item: MediaItem) {
        guard !favoriteItems.contains(where: { $0.id == item.id }) else {
            print("Item already in favorites")
            return
        }
        
        var newItem = item
        newItem.isFavorite = true
        
        favoriteItems.append(newItem)
        saveFavorites()
        
        print("❤️ Added to favorites: \(item.title)")
        UIImpactFeedbackGenerator.lightImpact()
    }
    
    func removeFromFavorites(_ item: MediaItem) {
        favoriteItems.removeAll { $0.id == item.id }
        saveFavorites()
        
        print("💔 Removed from favorites: \(item.title)")
        UIImpactFeedbackGenerator.lightImpact()
    }
    
    func toggleFavorite(_ item: MediaItem) {
        if favoriteItems.contains(where: { $0.id == item.id }) {
            removeFromFavorites(item)
        } else {
            addToFavorites(item)
        }
    }
    
    func isFavorite(_ item: MediaItem) -> Bool {
        return favoriteItems.contains { $0.id == item.id }
    }
    
    func clearAllFavorites() {
        favoriteItems.removeAll()
        saveFavorites()
        print("🗑️ Cleared all favorites")
    }
    
    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favoriteItems)
            userDefaults.set(encoded, forKey: favoritesKey)
            print("💾 Favorites saved")
        } catch {
            print("❌ Failed to save favorites: \(error)")
        }
    }
    
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey) else {
            print("📂 No saved favorites found")
            return
        }
        
        do {
            favoriteItems = try JSONDecoder().decode([MediaItem].self, from: data)
            print("📂 Loaded \(favoriteItems.count) favorites")
        } catch {
            print("❌ Failed to load favorites: \(error)")
            favoriteItems = []
        }
    }
}
