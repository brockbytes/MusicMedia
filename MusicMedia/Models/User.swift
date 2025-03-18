import Foundation
import FirebaseFirestore
import MediaPlayer
import FirebaseAuth

struct User: Identifiable, Codable {
    var id: String?
    let username: String
    let email: String
    var displayName: String
    var profileImageUrl: String?
    var bio: String?
    var currentlyPlaying: Song?
    var followers: [String]
    var following: [String]
    var posts: [Post]
    var listeningPrivacy: ListeningPrivacy
    var discoveryDistance: Double
    var notificationSettings: NotificationSettings
    
    // Friend-related computed properties
    var isFriend: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return followers.contains(currentUserId) && following.contains(currentUserId)
    }
    var friendRequestSent: Bool {
        get { false } // TODO: Implement friend request check logic
    }
    
    enum ListeningPrivacy: String, Codable {
        case public_ = "public_"
        case friendsOnly = "friendsOnly"
        case private_ = "private_"
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            switch rawValue {
            case "public_": self = .public_
            case "friendsOnly": self = .friendsOnly
            case "private_": self = .private_
            default: self = .public_
            }
        }
    }
    
    struct NotificationSettings: Codable {
        var newFollowers: Bool
        var nearbyListeners: Bool
        var friendActivity: Bool
        
        init(newFollowers: Bool = true, nearbyListeners: Bool = true, friendActivity: Bool = true) {
            self.newFollowers = newFollowers
            self.nearbyListeners = nearbyListeners
            self.friendActivity = friendActivity
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.newFollowers = try container.decodeIfPresent(Bool.self, forKey: .newFollowers) ?? true
            self.nearbyListeners = try container.decodeIfPresent(Bool.self, forKey: .nearbyListeners) ?? true
            self.friendActivity = try container.decodeIfPresent(Bool.self, forKey: .friendActivity) ?? true
        }
        
        enum CodingKeys: String, CodingKey {
            case newFollowers
            case nearbyListeners
            case friendActivity
        }
    }
    
    init(username: String, email: String, displayName: String) {
        self.username = username
        self.email = email
        self.displayName = displayName
        self.followers = []
        self.following = []
        self.posts = []
        self.listeningPrivacy = .public_
        self.discoveryDistance = 1000 // Default 1km
        self.notificationSettings = NotificationSettings()
        self.profileImageUrl = nil
        self.bio = nil
        self.currentlyPlaying = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decode(String.self, forKey: .email)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.currentlyPlaying = try container.decodeIfPresent(Song.self, forKey: .currentlyPlaying)
        self.followers = try container.decode([String].self, forKey: .followers)
        self.following = try container.decode([String].self, forKey: .following)
        self.posts = try container.decodeIfPresent([Post].self, forKey: .posts) ?? []
        
        // Special handling for listeningPrivacy
        if let privacyString = try container.decodeIfPresent(String.self, forKey: .listeningPrivacy) {
            switch privacyString {
            case "public_": self.listeningPrivacy = .public_
            case "friendsOnly": self.listeningPrivacy = .friendsOnly
            case "private_": self.listeningPrivacy = .private_
            default: self.listeningPrivacy = .public_
            }
        } else {
            self.listeningPrivacy = .public_
        }
        
        self.discoveryDistance = try container.decode(Double.self, forKey: .discoveryDistance)
        
        // Handle notification settings
        if let notificationDict = try container.decodeIfPresent([String: Bool].self, forKey: .notificationSettings) {
            self.notificationSettings = NotificationSettings(
                newFollowers: notificationDict["newFollowers"] ?? true,
                nearbyListeners: notificationDict["nearbyListeners"] ?? true,
                friendActivity: notificationDict["friendActivity"] ?? true
            )
        } else {
            self.notificationSettings = NotificationSettings()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(currentlyPlaying, forKey: .currentlyPlaying)
        try container.encode(followers, forKey: .followers)
        try container.encode(following, forKey: .following)
        try container.encode(posts, forKey: .posts)
        try container.encode(listeningPrivacy, forKey: .listeningPrivacy)
        try container.encode(discoveryDistance, forKey: .discoveryDistance)
        try container.encode(notificationSettings, forKey: .notificationSettings)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case displayName
        case profileImageUrl
        case bio
        case currentlyPlaying
        case followers
        case following
        case posts
        case listeningPrivacy
        case discoveryDistance
        case notificationSettings
    }
} 
