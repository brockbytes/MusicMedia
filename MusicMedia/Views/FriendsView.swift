import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var musicManager: MusicManager
    @State private var showingAddFriend = false
    
    var body: some View {
        NavigationView {
            List {
                if !musicManager.nearbyManager.nearbyUsers.isEmpty {
                    ForEach(Array(musicManager.nearbyManager.nearbyUsers), id: \.key) { userId, song in
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
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Add friends to see what they're listening to.")
                    )
                }
            }
            .listStyle(.plain)
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
    }
} 