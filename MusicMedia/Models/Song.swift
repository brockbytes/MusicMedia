import Foundation
import MediaPlayer

struct Song: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String?
    let artworkURL: String?
    let playbackDuration: TimeInterval
    var timestamp: Date
    
    init(from mediaItem: MPMediaItem) {
        self.id = mediaItem.persistentID.description
        self.title = mediaItem.title ?? "Unknown Title"
        self.artist = mediaItem.artist ?? "Unknown Artist"
        self.albumTitle = mediaItem.albumTitle
        self.artworkURL = nil // We'll need to handle artwork separately
        self.playbackDuration = mediaItem.playbackDuration
        self.timestamp = Date()
    }
    
    // Custom init for manual creation
    init(id: String, title: String, artist: String, albumTitle: String? = nil, 
         artworkURL: String? = nil, playbackDuration: TimeInterval = 0) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.artworkURL = artworkURL
        self.playbackDuration = playbackDuration
        self.timestamp = Date()
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
} 