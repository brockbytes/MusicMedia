import SwiftUI

struct AddSocialMediaView: View {
    let platform: String
    @State var username: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField(SocialMediaLink.getPlaceholder(for: platform), text: $username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } header: {
                Text("Enter your \(platform) \(SocialMediaLink.getPlaceholder(for: platform))")
            } footer: {
                Text("This will be displayed on your profile")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(platform)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(username)
                }
                .disabled(username.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationView {
        AddSocialMediaView(
            platform: "Instagram",
            username: "",
            onSave: { _ in }
        )
    }
} 