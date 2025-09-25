//
//  Constants.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import UIKit

struct Constants {
    static let youtubeAPIKey = "AIzaSyDd17pll0fiGezNeREiEOY-jgdCsKfZh5M"
    static let youtubeBaseURL = "https://www.googleapis.com/youtube/v3"
    static let maxPlaylistItems = 20
    static let maxSearchResults = 50
    static let shakeThreshold: Double = 2.5
    static let defaultAnimationDuration: Double = 0.3
    static let longAnimationDuration: Double = 0.6
    static let shortAnimationDuration: Double = 0.15
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 25
    static let shadowRadius: CGFloat = 4
    static let defaultPadding: CGFloat = 16
    static let favoritesKey = "MoodifyFavorites"
    static let playlistCacheKey = "MoodifyPlaylistCache"
    static let userPreferencesKey = "MoodifyUserPreferences"
  
    static let networkErrorMessage = "Unable to connect to the internet. Please check your connection and try again."
    static let apiErrorMessage = "Something went wrong. Please try again later."
    static let locationErrorMessage = "Location access is required to find nearby concerts."
    static let microphoneErrorMessage = "Microphone access is required for voice search."

    static let enableVoiceSearch = true
    static let enableShakeDetection = true
    static let enableLocationServices = true

    #if DEBUG
    static let isDebugMode = true
    static let enableMockData = true
    #else
    static let isDebugMode = false
    static let enableMockData = false
    #endif
}

extension Color {
    static let moodifyPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let moodifyPink = Color(red: 0.9, green: 0.4, blue: 0.6)
    static let moodifyBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let moodifyGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let moodifyOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let moodifyYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
}

extension String {
    func youtubeEmbedURL() -> String {
        return "https://www.youtube.com/embed/\(self)"
    }
    
    func sanitizedForSearch() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func glow(color: Color = .white, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

extension UIImpactFeedbackGenerator {
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

enum UserDefaultsKeys {
    static let hasSeenWelcome = "hasSeenWelcome"
    static let selectedMood = "selectedMood"
    static let enableNotifications = "enableNotifications"
    static let autoShuffleEnabled = "autoShuffleEnabled"
}
extension Notification.Name {
    static let moodChanged = Notification.Name("MoodChanged")
    static let playlistUpdated = Notification.Name("PlaylistUpdated")
    static let favoriteToggled = Notification.Name("FavoriteToggled")
}
enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
    case unauthorized
    case quotaExceeded
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        case .quotaExceeded:
            return "API quota exceeded"
        }
    }
}
