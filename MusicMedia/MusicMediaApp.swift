//
//  MusicMediaApp.swift
//  MusicMedia
//
//  Created by Brockton Carnes on 3/13/25.
//

import SwiftUI
import Firebase

@main
struct MusicMediaApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var musicManager = MusicManager()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(musicManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
            }
            
            NavigationView {
                NowPlayingView()
            }
            .tabItem {
                Label("Playing", systemImage: "music.note")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
    }
}
