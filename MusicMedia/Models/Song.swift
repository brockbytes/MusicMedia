import Foundation
import MusicKit

struct Song: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String
    let artworkURL: URL?
    let playbackDate: Date
    
    // Add coding keys to handle the artwork URL
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case albumTitle
        case artworkURL
        case playbackDate
    }
    
    // Custom encoding to handle the local file URL
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(albumTitle, forKey: .albumTitle)
        try container.encode(playbackDate, forKey: .playbackDate)
        
        // For artworkURL, we need to send the actual image data
        if let artworkURL = artworkURL,
           let imageData = try? Data(contentsOf: artworkURL) {
            // Convert the image data to a base64 string
            let base64String = imageData.base64EncodedString()
            try container.encode("data:image/jpeg;base64," + base64String, forKey: .artworkURL)
        } else {
            try container.encodeNil(forKey: .artworkURL)
        }
    }
    
    // Custom decoding to handle the base64 image data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        albumTitle = try container.decode(String.self, forKey: .albumTitle)
        playbackDate = try container.decode(Date.self, forKey: .playbackDate)
        
        // Handle the artwork URL
        if let base64String = try container.decodeIfPresent(String.self, forKey: .artworkURL),
           base64String.hasPrefix("data:image/jpeg;base64,") {
            let base64Data = String(base64String.dropFirst("data:image/jpeg;base64,".count))
            if let imageData = Data(base64Encoded: base64Data) {
                // Save the image data to a temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "\(id)_received.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)
                try? imageData.write(to: fileURL)
                artworkURL = fileURL
            } else {
                artworkURL = nil
            }
        } else {
            artworkURL = nil
        }
    }
    
    init(id: String, title: String, artist: String, albumTitle: String, artworkURL: URL?, playbackDate: Date) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.artworkURL = artworkURL
        self.playbackDate = playbackDate
    }
    
    init(from musicItem: MusicItem) {
        if let song = musicItem as? MusicKit.Song {
            self.id = song.id.description
            self.title = song.title
            self.artist = song.artistName
            self.albumTitle = song.albumTitle ?? ""
            if let artwork = song.artwork {
                self.artworkURL = artwork.url(width: 300, height: 300)
            } else {
                self.artworkURL = nil
            }
        } else {
            self.id = UUID().uuidString
            self.title = ""
            self.artist = ""
            self.albumTitle = ""
            self.artworkURL = nil
        }
        self.playbackDate = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
} 