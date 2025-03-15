import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let username: String
    let email: String
    var displayName: String
    var profileImageUrl: String?
    var bio: String?
    var currentlyPlaying: Song?
    var followers: [String]
    var following: [String]
    var listeningPrivacy: ListeningPrivacy
    var discoveryDistance: Double
    var notificationSettings: NotificationSettings
    
    enum ListeningPrivacy: String, Codable {
        case public_
        case friendsOnly
        case private_
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
    }
    
    init(username: String, email: String, displayName: String) {
        self.username = username
        self.email = email
        self.displayName = displayName
        self.followers = []
        self.following = []
        self.listeningPrivacy = .public_
        self.discoveryDistance = 1000 // Default 1km
        self.notificationSettings = NotificationSettings()
    }
} 
