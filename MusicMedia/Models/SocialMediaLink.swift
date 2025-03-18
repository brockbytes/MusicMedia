import Foundation

struct SocialMediaLink: Identifiable {
    let id = UUID()
    let platform: String
    var username: String
    
    static let platforms = [
        "Instagram",
        "Twitter/X",
        "Facebook",
        "TikTok"
    ]
    
    static func getIcon(for platform: String) -> String {
        switch platform {
        case "Instagram": return "camera.circle.fill"
        case "Twitter/X": return "message.circle.fill"
        case "Facebook": return "person.circle.fill"
        case "TikTok": return "play.circle.fill"
        default: return "link.circle.fill"
        }
    }
    
    static func getPlaceholder(for platform: String) -> String {
        switch platform {
        case "Instagram": return "username"
        case "Twitter/X": return "username"
        case "Facebook": return "profile name or URL"
        case "TikTok": return "@username"
        default: return "username"
        }
    }
} 