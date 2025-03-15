import SwiftUI

struct MainTabView: View {
    @StateObject private var tabSelection = TabSelection()
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(Tab.home)
            
            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
            }
            .tag(Tab.explore)
            
            NavigationView {
                NowPlayingView()
            }
            .tabItem {
                Label("Now Playing", systemImage: "play.circle.fill")
            }
            .tag(Tab.nowPlaying)
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
    }
}

class TabSelection: ObservableObject {
    @Published var selectedTab: Tab = .home
}

enum Tab {
    case home
    case explore
    case nowPlaying
    case profile
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(MusicManager())
} 