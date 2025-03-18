import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSigningOut = false
    
    var body: some View {
        List {
            // Profile Section
            Section("Profile") {
                Button {
                    showingEditProfile = true
                } label: {
                    HStack {
                        Text("Edit Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                
                NavigationLink {
                    PermissionsView()
                } label: {
                    HStack {
                        Text("Photo Library Access")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.photoLibrary]?.displayText ?? "Not Set")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Music Settings
            Section("Music") {
                NavigationLink {
                    PermissionsView()
                } label: {
                    HStack {
                        Text("Music Library Access")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.music]?.displayText ?? "Not Set")
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("Show Mini Player", isOn: .constant(true))
                    .tint(.accentColor)
            }
            
            // Nearby Settings
            Section("Nearby") {
                NavigationLink {
                    PermissionsView()
                } label: {
                    HStack {
                        Text("Location Access")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.location]?.displayText ?? "Not Set")
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("Visible to Nearby Users", isOn: .constant(true))
                    .tint(.accentColor)
            }
            
            // Notifications
            Section("Notifications") {
                NavigationLink {
                    PermissionsView()
                } label: {
                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.notifications]?.displayText ?? "Not Set")
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("Friend Requests", isOn: .constant(true))
                    .tint(.accentColor)
                
                Toggle("Now Playing Updates", isOn: .constant(true))
                    .tint(.accentColor)
            }
            
            // Privacy
            Section("Privacy") {
                Toggle("Share Listening Activity", isOn: .constant(true))
                    .tint(.accentColor)
                
                Toggle("Allow Friend Requests", isOn: .constant(true))
                    .tint(.accentColor)
            }
            
            // Account
            Section {
                Button(role: .destructive) {
                    isSigningOut = true
                    Task {
                        do {
                            // Clear any cached data
                            UserDefaults.standard.synchronize()
                            // Sign out
                            try await authManager.signOut()
                            await MainActor.run {
                                isSigningOut = false
                                dismiss() // This will dismiss the settings sheet
                            }
                        } catch {
                            print("❌ Error signing out: \(error)")
                            await MainActor.run {
                                isSigningOut = false
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                } label: {
                    if isSigningOut {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    } else {
                        Text("Sign Out")
                    }
                }
                .disabled(isSigningOut)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .interactiveDismissDisabled(isSigningOut)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(PermissionsManager())
            .environmentObject(AuthManager())
            .environmentObject(MusicManager())
    }
}

// Add displayText extension if not already present
extension PermissionStatus {
    var displayText: String {
        switch self {
        case .notDetermined: return "Not Set"
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        }
    }
} 