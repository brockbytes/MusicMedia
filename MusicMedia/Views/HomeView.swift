import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack {
            Text("Home")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Coming soon...")
        }
        .navigationTitle("Home")
    }
} 