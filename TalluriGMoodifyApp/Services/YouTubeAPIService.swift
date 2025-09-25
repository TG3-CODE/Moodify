//
//  YouTubeAPIService.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation

class YouTubeAPIService: ObservableObject {
    private let baseURL = Constants.youtubeBaseURL
    private let apiKey = Constants.youtubeAPIKey
    
    func searchMusic(query: String) async throws -> [MediaItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search?part=snippet&type=video&videoCategoryId=10&maxResults=\(Constants.maxPlaylistItems)&q=\(encodedQuery)&key=\(apiKey)"
        
        print("🔍 YouTube API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 YouTube API Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 403 {
                throw APIError.quotaExceeded
            }
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            
            return searchResponse.items.map { item in
                MediaItem(
                    id: item.id.videoId,
                    title: item.snippet.title,
                    artist: item.snippet.channelTitle,
                    thumbnailURL: item.snippet.thumbnails.default.url,
                    videoURL: "https://www.youtube.com/watch?v=\(item.id.videoId)"
                )
            }
        } catch {
            print("❌ Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    func searchVideos(for mood: MoodType) async throws -> [MediaItem] {
        let searchQuery = getSearchQuery(for: mood)
        return try await searchMusic(query: searchQuery)
    }
    
    private func getSearchQuery(for mood: MoodType) -> String {
        switch mood {
        case .happy: return "happy upbeat pop music 2024"
        case .sad: return "sad emotional ballad music"
        case .energetic: return "energetic workout pump up music"
        case .chill: return "chill lo-fi relaxing music"
        case .angry: return "rock metal aggressive music"
        case .romantic: return "romantic love songs R&B"
        }
    }
}
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeItem]
}

struct YouTubeItem: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeSnippet: Codable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
}

struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}
