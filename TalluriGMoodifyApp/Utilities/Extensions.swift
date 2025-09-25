//
//  Extensions.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension String {
    func truncated(toLength length: Int) -> String {
        if self.count > length {
            return String(self.prefix(length)) + "..."
        }
        return self
    }
    
    var isValidURL: Bool {
        return URL(string: self) != nil
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        self.removeAll { $0 == element }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func onTapToHideKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

extension Color {
    static func moodColor(for mood: MoodType) -> Color {
        switch mood {
        case .happy:
            return .moodifyYellow
        case .sad:
            return .moodifyBlue
        case .energetic:
            return .red
        case .chill:
            return .moodifyGreen
        case .angry:
            return .moodifyOrange
        case .romantic:
            return .moodifyPink
        }
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UserDefaults {
    func setMood(_ mood: MoodType, forKey key: String) {
        set(mood.rawValue, forKey: key)
    }
    
    func mood(forKey key: String) -> MoodType? {
        guard let rawValue = string(forKey: key) else { return nil }
        return MoodType(rawValue: rawValue)
    }
}

extension Notification.Name {
    static let userLocationUpdated = Notification.Name("UserLocationUpdated")
    static let audioPlaybackStateChanged = Notification.Name("AudioPlaybackStateChanged")
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}
extension URL {
    static func youtubeWatch(videoId: String) -> URL? {
        return URL(string: "https://www.youtube.com/watch?v=\(videoId)")
    }
    
    static func youtubeEmbed(videoId: String) -> URL? {
        return URL(string: "https://www.youtube.com/embed/\(videoId)")
    }
}
