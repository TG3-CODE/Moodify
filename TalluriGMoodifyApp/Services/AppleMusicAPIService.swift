//
//  AppleMusicAPIService.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//
import Foundation
import MusicKit
import MediaPlayer

@available(iOS 15.0, *)
class AppleMusicAPIService: ObservableObject {
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        await MainActor.run {
            authorizationStatus = status
        }
        print("🎵 Apple Music authorization status: \(status)")
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let status = await MusicAuthorization.currentStatus
            await MainActor.run {
                authorizationStatus = status
            }
        }
    }
    func searchMusic(query: String, limit: Int = 20) async throws -> [MediaItem] {
        guard authorizationStatus == .authorized else {
            await requestMusicAuthorization()
            guard authorizationStatus == .authorized else {
                throw AppleMusicError.notAuthorized
            }
            throw AppleMusicError.notAuthorized
        }
        var searchRequest = MusicCatalogSearchRequest(
            term: query,
            types: [Song.self]
        )
        searchRequest.limit = limit
        
        do {
            let searchResponse = try await searchRequest.response()
            
            return searchResponse.songs.compactMap { song in
                MediaItem(
                    id: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    thumbnailURL: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                    videoURL: song.previewAssets?.first?.url?.absoluteString ?? "",
                    duration: formatDuration(song.duration ?? 0)
                )
            }
        } catch {
            print("❌ Apple Music search error: \(error)")
            throw AppleMusicError.searchFailed
        }
    }
    func searchByMood(_ mood: MoodType) async throws -> [MediaItem] {
        let searchQuery = getMoodSearchQuery(for: mood)
        return try await searchMusic(query: searchQuery)
    }
    func getMoodPlaylists(_ mood: MoodType) async throws -> [MediaItem] {
        guard authorizationStatus == .authorized else {
            await requestMusicAuthorization()
            guard authorizationStatus == .authorized else {
                throw AppleMusicError.notAuthorized
            }
            throw AppleMusicError.notAuthorized
        }
        let playlistQuery = getMoodPlaylistQuery(for: mood)
        var searchRequest = MusicCatalogSearchRequest(
            term: playlistQuery,
            types: [Playlist.self]
        )
        searchRequest.limit = 5
        
        do {
            let searchResponse = try await searchRequest.response()
            var allSongs: [MediaItem] = []
            if let firstPlaylist = searchResponse.playlists.first {
                let detailedPlaylist = try await firstPlaylist.with(.tracks)
                
                if let tracks = detailedPlaylist.tracks {
                    for track in tracks.prefix(20) {
                        if let song = track as? Song {
                            let mediaItem = MediaItem(
                                id: song.id.rawValue,
                                title: song.title,
                                artist: song.artistName,
                                thumbnailURL: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                                videoURL: song.previewAssets?.first?.url?.absoluteString ?? "",
                                duration: formatDuration(song.duration ?? 0)
                            )
                            allSongs.append(mediaItem)
                        }
                    }
                }
            }
            
            return allSongs
        } catch {
            print("❌ Failed to get mood playlists: \(error)")
            return try await searchByMood(mood)
        }
    }
    func playFullSong(_ mediaItem: MediaItem) async throws {
        guard authorizationStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        let player = ApplicationMusicPlayer.shared
        let songID = MusicItemID(mediaItem.id)
        let song = try await Song(from: songID as! Decoder)
        
        player.queue = ApplicationMusicPlayer.Queue(for: [song])
        try await player.play()
    }
    private func getMoodSearchQuery(for mood: MoodType) -> String {
        switch mood {
        case .happy:
            return "happy upbeat pop feel good"
        case .sad:
            return "sad emotional ballad melancholy"
        case .energetic:
            return "energetic workout pump up dance"
        case .chill:
            return "chill relaxing ambient lo-fi"
        case .angry:
            return "rock metal aggressive intense"
        case .romantic:
            return "romantic love songs r&b"
        }
    }
    
    private func getMoodPlaylistQuery(for mood: MoodType) -> String {
        switch mood {
        case .happy:
            return "Feel Good Hits"
        case .sad:
            return "Sad Songs"
        case .energetic:
            return "Workout Mix"
        case .chill:
            return "Chill Vibes"
        case .angry:
            return "Rock Hits"
        case .romantic:
            return "Love Songs"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    func getUserLibraryPlaylists() async throws -> [String] {
        guard authorizationStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        
        return response.items.map { $0.name }
    }
}
enum AppleMusicError: Error, LocalizedError {
    case notAuthorized
    case searchFailed
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Apple Music access not authorized"
        case .searchFailed:
            return "Failed to search Apple Music"
        case .playbackFailed:
            return "Failed to play song"
        }
    }
}
class LegacyAppleMusicService: ObservableObject {
    private let developerToken = "YOUR_APPLE_MUSIC_DEVELOPER_TOKEN"
    private let baseURL = "https://api.music.apple.com/v1"
    
    func searchMusic(query: String, limit: Int = 20) async throws -> [MediaItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/catalog/us/search?term=\(encodedQuery)&types=songs&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🎵 Apple Music API Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
        }
        
        let searchResponse = try JSONDecoder().decode(AppleMusicSearchResponse.self, from: data)
        
        return searchResponse.results.songs?.data.compactMap { song in
            MediaItem(
                id: song.id,
                title: song.attributes.name,
                artist: song.attributes.artistName,
                thumbnailURL: song.attributes.artwork?.url.replacingOccurrences(of: "{w}", with: "300").replacingOccurrences(of: "{h}", with: "300") ?? "",
                videoURL: song.attributes.previews?.first?.url ?? "",
                duration: formatDuration(song.attributes.durationInMillis)
            )
        } ?? []
    }
    
    private func formatDuration(_ milliseconds: Int?) -> String {
        guard let ms = milliseconds else { return "0:00" }
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct AppleMusicSearchResponse: Codable {
    let results: AppleMusicSearchResults
}

struct AppleMusicSearchResults: Codable {
    let songs: AppleMusicSongsResponse?
}

struct AppleMusicSongsResponse: Codable {
    let data: [AppleMusicSong]
}

struct AppleMusicSong: Codable {
    let id: String
    let type: String
    let attributes: AppleMusicSongAttributes
}

struct AppleMusicSongAttributes: Codable {
    let name: String
    let artistName: String
    let albumName: String
    let durationInMillis: Int?
    let artwork: AppleMusicArtwork?
    let previews: [AppleMusicPreview]?
}

struct AppleMusicArtwork: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct AppleMusicPreview: Codable {
    let url: String
}
