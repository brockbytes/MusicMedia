import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack {
            Text("Now Playing")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let currentSong = musicManager.currentSong {
                VStack(spacing: 10) {
                    Text(currentSong.title)
                        .font(.title2)
                    Text(currentSong.artist)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No song playing")
                    .foregroundColor(.secondary)
            }
            
            // Music controls placeholder
            HStack(spacing: 40) {
                Button(action: musicManager.skipToPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                
                Button(action: {
                    if musicManager.isPlaying {
                        musicManager.pause()
                    } else {
                        musicManager.play()
                    }
                }) {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Button(action: musicManager.skipToNext) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
            .padding()
            
            Button("Select Music") {
                musicManager.showMediaPicker()
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .navigationTitle("Now Playing")
        .task {
            _ = await musicManager.requestMusicAuthorization()
        }
    }
} 