import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let song: Song
    let caption: String?
    let timestamp: Date
    var likes: [String]
    var comments: [Comment]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case song
        case caption
        case timestamp
        case likes
        case comments
    }
    
    init(userId: String, song: Song, caption: String? = nil) {
        self.userId = userId
        self.song = song
        self.caption = caption
        self.timestamp = Date()
        self.likes = []
        self.comments = []
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        song = try container.decode(Song.self, forKey: .song)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        likes = try container.decodeIfPresent([String].self, forKey: .likes) ?? []
        comments = try container.decodeIfPresent([Comment].self, forKey: .comments) ?? []
    }
}

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let text: String
    let timestamp: Date
    
    init(userId: String, text: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.text = text
        self.timestamp = Date()
    }
} 