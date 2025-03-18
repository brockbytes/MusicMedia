import SwiftUI
import Photos
import UIKit

struct PermissionsView: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(PermissionType.allCases, id: \.self) { permission in
                PermissionRow(type: permission)
            }
        }
        .navigationTitle("Permissions")
    }
}

struct PermissionRow: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    let type: PermissionType
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(type.rawValue)
                    .font(.headline)
                Text(statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                handlePermissionAction()
            }) {
                Text(buttonTitle)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handlePermissionAction() {
        switch status {
        case .notDetermined:
            Task {
                await permissionsManager.requestPermission(type)
            }
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
    
    private var status: PermissionStatus {
        permissionsManager.permissionStatuses[type] ?? .notDetermined
    }
    
    private var statusDescription: String {
        switch status {
        case .notDetermined:
            return "Permission not requested"
        case .authorized:
            return "Access granted"
        case .denied:
            return "Access denied. Tap to open Settings"
        case .restricted:
            return "Access restricted. Tap to open Settings"
        }
    }
    
    private var buttonTitle: String {
        switch status {
        case .notDetermined:
            return "Request Access"
        case .authorized:
            return "Enabled"
        case .denied, .restricted:
            return "Open Settings"
        }
    }
}

#Preview {
    NavigationView {
        PermissionsView()
            .environmentObject(PermissionsManager())
    }
} 