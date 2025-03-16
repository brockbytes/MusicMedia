import SwiftUI
import MediaPlayer
import MusicKit

struct NowPlayingView: View {
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack(spacing: 20) {
            if musicManager.authorizationStatus == .authorized {
                if let track = musicManager.currentSong {
                    // Artwork
                    if let artworkURL = track.artworkURL,
                       let artworkData = try? Data(contentsOf: artworkURL),
                       let artwork = UIImage(data: artworkData) {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 300)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 300)
                            .foregroundColor(.gray)
                    }
                    
                    // Track Info
                    VStack(spacing: 8) {
                        Text(track.title)
                            .font(.title)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text(track.artist)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        // Source indicator
                        HStack {
                            Image(systemName: sourceIcon(for: .appleMusic))
                            Text(sourceLabel(for: .appleMusic))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Playback Controls
                    HStack(spacing: 40) {
                        Button(action: {
                            Task {
                                try? await musicManager.skipToPrevious()
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                        }
                        
                        Button(action: {
                            Task {
                                try? await musicManager.togglePlayPause()
                            }
                        }) {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 45))
                        }
                        
                        Button(action: {
                            Task {
                                try? await musicManager.skipToNext()
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Track Playing")
                            .font(.title2)
                        
                        Text("Play music from Apple Music to see it here")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Music Library Access Required")
                        .font(.title2)
                    
                    Text("Please enable access to your music library in Settings to use this feature.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Now Playing")
    }
    
    private func sourceIcon(for source: MusicSource) -> String {
        switch source {
        case .appleMusic:
            return "music.note"
        case .spotify:
            return "s.circle"
        }
    }
    
    private func sourceLabel(for source: MusicSource) -> String {
        switch source {
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        }
    }
} 