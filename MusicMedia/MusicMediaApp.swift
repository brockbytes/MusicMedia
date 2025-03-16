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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var permissionsManager = PermissionsManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                TabView {
                    NearbyView()
                        .tabItem {
                            Label("Nearby", systemImage: "wave.3.right")
                        }
                    
                    FriendsView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                }
                
                VStack(spacing: 0) {
                    MiniPlayerView()
                    Spacer().frame(height: 49) // Height of tab bar
                }
            }
            .environmentObject(authManager)
            .environmentObject(musicManager)
            .environmentObject(locationManager)
            .environmentObject(notificationManager)
            .environmentObject(permissionsManager)
        }
    }
}
