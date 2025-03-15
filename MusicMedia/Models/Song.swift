import Foundation
import MediaPlayer

struct Song: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String?
    let artworkURL: String?
    let duration: TimeInterval
    var playbackPosition: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case albumTitle
        case artworkURL
        case duration
        case playbackPosition
    }
    
    init(from mediaItem: MPMediaItem) {
        self.id = mediaItem.persistentID.description
        self.title = mediaItem.title ?? "Unknown Title"
        self.artist = mediaItem.artist ?? "Unknown Artist"
        self.albumTitle = mediaItem.albumTitle
        self.artworkURL = nil // We'll need to handle artwork separately
        self.duration = mediaItem.playbackDuration
        self.playbackPosition = nil
    }
    
    init(id: String, title: String, artist: String, albumTitle: String? = nil, artworkURL: String? = nil, duration: TimeInterval = 0, playbackPosition: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.artworkURL = artworkURL
        self.duration = duration
        self.playbackPosition = playbackPosition
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        albumTitle = try container.decodeIfPresent(String.self, forKey: .albumTitle)
        artworkURL = try container.decodeIfPresent(String.self, forKey: .artworkURL)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        playbackPosition = try container.decodeIfPresent(TimeInterval.self, forKey: .playbackPosition)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encodeIfPresent(albumTitle, forKey: .albumTitle)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(playbackPosition, forKey: .playbackPosition)
    }
} 