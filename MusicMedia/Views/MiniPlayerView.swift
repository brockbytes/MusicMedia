import SwiftUI
import MediaPlayer

struct MiniPlayerView: View {
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        if let track = musicManager.currentSong {
            HStack(spacing: 12) {
                // Artwork
                if let artworkURL = track.artworkURL,
                   let artworkData = try? Data(contentsOf: artworkURL),
                   let artwork = UIImage(data: artworkData) {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
                
                // Track Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: {
                        Task {
                            try? await musicManager.skipToPrevious()
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                    }
                    
                    Button(action: {
                        Task {
                            try? await musicManager.togglePlayPause()
                        }
                    }) {
                        Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                    }
                    
                    Button(action: {
                        Task {
                            try? await musicManager.skipToNext()
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                    }
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(.regularMaterial)
                    .shadow(radius: 3, y: -2)
            )
        }
    }
} 