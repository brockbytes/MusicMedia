import SwiftUI

struct UserSongListItem: View {
    let song: Song
    let username: String
    let profileImage: Image?
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = song.artworkURL,
               let artworkData = try? Data(contentsOf: artworkURL),
               let artwork = UIImage(data: artworkData) {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(4)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Profile image or fallback
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // More button
            Menu {
                Button(action: {
                    // Add view profile action
                }) {
                    Label("View Profile", systemImage: "person")
                }
                
                Button(action: {
                    // Add to playlist action
                }) {
                    Label("Add to Playlist", systemImage: "plus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
} 