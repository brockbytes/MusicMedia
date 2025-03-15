import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Permissions") {
                    ForEach(PermissionType.allCases, id: \.self) { permission in
                        PermissionRow(type: permission)
                    }
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await authManager.signOut()
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct PermissionRow: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    let type: PermissionType
    
    var body: some View {
        Button(action: {
            handlePermissionTap()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.body)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let status = permissionsManager.permissionStatuses[type] {
                    switch status {
                    case .authorized:
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    case .denied, .restricted:
                        Text("Off")
                            .foregroundColor(.secondary)
                    case .notDetermined:
                        Text("Off")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    private func handlePermissionTap() {
        guard let status = permissionsManager.permissionStatuses[type] else { return }
        
        switch status {
        case .notDetermined:
            // Try to request permission first if not determined
            Task {
                await permissionsManager.requestPermission(type)
            }
        case .denied, .restricted:
            // If denied or restricted, open system settings
            permissionsManager.openSettings()
        case .authorized:
            // If already authorized, just open system settings
            permissionsManager.openSettings()
        }
    }
    
    private var statusDescription: String {
        guard let status = permissionsManager.permissionStatuses[type] else {
            return ""
        }
        
        switch status {
        case .notDetermined:
            return "Access not determined"
        case .authorized:
            return "Access granted"
        case .denied:
            return "Access denied"
        case .restricted:
            return "Access restricted"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PermissionsManager())
        .environmentObject(AuthManager())
} 