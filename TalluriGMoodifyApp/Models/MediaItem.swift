//
//  MediaItem.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation

struct MediaItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let videoURL: String
    let duration: String
    var isFavorite: Bool = false
    
    init(id: String, title: String, artist: String, thumbnailURL: String, videoURL: String, duration: String = "3:45") {
        self.id = id
        self.title = title
        self.artist = artist
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.duration = duration
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        return lhs.id == rhs.id
    }
}
