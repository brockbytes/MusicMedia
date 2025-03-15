import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack {
            Text("Explore")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Coming soon...")
        }
        .navigationTitle("Explore")
    }
} 