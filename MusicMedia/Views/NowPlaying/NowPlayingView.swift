import SwiftUI
import MediaPlayer

struct NowPlayingView: View {
    @EnvironmentObject var musicManager: MusicManager
    @State private var showingMusicPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if musicManager.isAuthorized {
                    if let track = musicManager.currentTrack {
                        // Artwork
                        if let artwork = track.artwork {
                            Image(uiImage: artwork.image(at: CGSize(width: 300, height: 300)) ?? UIImage())
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
                                Image(systemName: sourceIcon(for: track.source))
                                Text(sourceLabel(for: track.source))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Playback Controls
                        HStack(spacing: 40) {
                            Button(action: { musicManager.skipToPreviousItem() }) {
                                Image(systemName: "backward.fill")
                                    .font(.title)
                            }
                            
                            Button(action: {
                                if musicManager.playbackState == .playing {
                                    musicManager.pause()
                                } else {
                                    musicManager.play()
                                }
                            }) {
                                Image(systemName: musicManager.playbackState == .playing ? "pause.fill" : "play.fill")
                                    .font(.system(size: 45))
                            }
                            
                            Button(action: { musicManager.skipToNextItem() }) {
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
                            
                            Button("Choose Music") {
                                showingMusicPicker = true
                            }
                            .buttonStyle(.bordered)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMusicPicker = true }) {
                        Image(systemName: "music.note.list")
                    }
                    .disabled(!musicManager.isAuthorized)
                }
            }
        }
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