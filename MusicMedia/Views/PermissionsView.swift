import SwiftUI

struct PermissionsView: View {
    @StateObject private var permissionsManager = PermissionsManager()
    
    var body: some View {
        List {
            Section(header: Text("App Permissions")) {
                // Music Library Permission
                Button(action: {
                    permissionsManager.openSettings()
                }) {
                    HStack {
                        Text("Music Library")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.music]?.displayText ?? "Not Determined")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Location Permission
                Button(action: {
                    permissionsManager.openSettings()
                }) {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.location]?.displayText ?? "Not Determined")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notifications Permission
                Button(action: {
                    permissionsManager.openSettings()
                }) {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.notifications]?.displayText ?? "Not Determined")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Microphone Permission
                Button(action: {
                    permissionsManager.openSettings()
                }) {
                    HStack {
                        Text("Microphone")
                        Spacer()
                        Text(permissionsManager.permissionStatuses[.microphone]?.displayText ?? "Not Determined")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(footer: Text("Permission settings can be changed in the iOS Settings app.")) {
                EmptyView()
            }
        }
        .navigationTitle("Permissions")
    }
}

// Extension to provide user-friendly status text
extension PermissionStatus {
    var displayText: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .authorized:
            return "Allowed"
        case .denied:
            return "Not Allowed"
        case .restricted:
            return "Restricted"
        }
    }
}

#Preview {
    NavigationView {
        PermissionsView()
    }
} 