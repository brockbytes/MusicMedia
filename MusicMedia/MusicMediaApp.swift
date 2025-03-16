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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var permissionsManager = PermissionsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(musicManager)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(permissionsManager)
        }
    }
}
