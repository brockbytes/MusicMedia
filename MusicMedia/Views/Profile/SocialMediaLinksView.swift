import SwiftUI

struct SocialMediaLinksView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var socialLinks: [SocialMediaLink] = []
    @State private var editingLink: SocialMediaLink?
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            ForEach(SocialMediaLink.platforms, id: \.self) { platform in
                if let existingLink = socialLinks.first(where: { $0.platform == platform }) {
                    Button {
                        editingLink = existingLink
                        showingEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: SocialMediaLink.getIcon(for: platform))
                                .foregroundColor(.accentColor)
                            Text(platform)
                            Spacer()
                            Text(existingLink.username)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } else {
                    Button {
                        editingLink = SocialMediaLink(platform: platform, username: "")
                        showingEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: SocialMediaLink.getIcon(for: platform))
                                .foregroundColor(.accentColor)
                            Text(platform)
                            Spacer()
                            Text("Add")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("Social Media Links")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let link = editingLink {
                NavigationView {
                    AddSocialMediaView(
                        platform: link.platform,
                        username: link.username,
                        onSave: { newUsername in
                            if let index = socialLinks.firstIndex(where: { $0.platform == link.platform }) {
                                socialLinks[index].username = newUsername
                            } else {
                                socialLinks.append(SocialMediaLink(platform: link.platform, username: newUsername))
                            }
                            showingEditSheet = false
                        }
                    )
                }
            }
        }
    }
}

struct SocialMediaLinksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SocialMediaLinksView()
        }
    }
} 