import SwiftUI

struct NearbyView: View {
    @EnvironmentObject var musicManager: MusicManager
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List {
                let nearbyUsers = musicManager.nearbyManager.nearbyUsers
                let isEmpty = nearbyUsers.isEmpty
                
                // Debug print
                let _ = print("🔄 NearbyView updating - Users count: \(nearbyUsers.count)")
                
                if !isEmpty {
                    ForEach(Array(nearbyUsers), id: \.key) { userId, song in
                        let _ = print("📱 Displaying user: \(userId) with song: \(song.title)")
                        UserSongListItem(
                            song: song,
                            username: userId,
                            profileImage: nil,
                            timestamp: song.playbackDate
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                } else {
                    ContentUnavailableView(
                        "No One Nearby",
                        systemImage: "wave.3.right",
                        description: Text("When people around you are listening to music, you'll see them here.")
                    )
                }
            }
            .listStyle(.plain)
            .navigationTitle("Nearby")
            .onAppear {
                viewModel.startUpdateTimer(nearbyManager: musicManager.nearbyManager)
            }
        }
    }
    
    class ViewModel: ObservableObject {
        private var timer: Timer?
        
        func startUpdateTimer(nearbyManager: NearbyConnectionManager) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                print("🔍 Checking nearby users - count: \(nearbyManager.nearbyUsers.count)")
                print("🎵 Current songs: \(nearbyManager.nearbyUsers.map { "\($0.key): \($0.value.title)" }.joined(separator: ", "))")
                self?.objectWillChange.send()
            }
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}

// Helper struct to make the type explicit for ForEach
struct NearbyUser: Identifiable {
    let id: String
    let name: String
    let currentSong: Song?
    let profileImage: UIImage?
} 