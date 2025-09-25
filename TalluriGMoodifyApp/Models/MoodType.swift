//
//  MoodType.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

enum MoodType: String, CaseIterable, Codable {
    case happy = "Happy"
    case sad = "Sad"
    case energetic = "Energetic"
    case chill = "Chill"
    case angry = "Angry"
    case romantic = "Romantic"
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .energetic: return "⚡"
        case .chill: return "😌"
        case .angry: return "😤"
        case .romantic: return "💕"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .sad: return .blue
        case .energetic: return .red
        case .chill: return .green
        case .angry: return .orange
        case .romantic: return .pink
        }
    }
    
    var description: String {
        switch self {
        case .happy: return "Upbeat and joyful music"
        case .sad: return "Emotional and melancholic songs"
        case .energetic: return "High-energy workout music"
        case .chill: return "Relaxing and calm vibes"
        case .angry: return "Intense and aggressive beats"
        case .romantic: return "Love songs and romantic ballads"
        }
    }
}
