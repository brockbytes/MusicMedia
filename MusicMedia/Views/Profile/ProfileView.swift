import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 20) {
                            // Profile Image
                            if let user = authManager.currentUser,
                               let profileImageUrl = user.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 86, height: 86)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 86, height: 86)
                                            .clipShape(Circle())
                                    case .failure(_):
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .frame(width: 86, height: 86)
                                    @unknown default:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .frame(width: 86, height: 86)
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 86, height: 86)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if let user = authManager.currentUser {
                                    Text(user.displayName)
                                        .font(.subheadline)
                                }
                                
                                // Stats
                                HStack(spacing: 30) {
                                    VStack {
                                        Text("\(authManager.currentUser?.posts.count ?? 0)")
                                            .font(.headline)
                                        Text("Posts")
                                            .font(.caption)
                                    }
                                    
                                    VStack {
                                        Text("\(authManager.currentUser?.followers.count ?? 0)")
                                            .font(.headline)
                                        Text("Followers")
                                            .font(.caption)
                                    }
                                    
                                    VStack {
                                        Text("\(authManager.currentUser?.following.count ?? 0)")
                                            .font(.headline)
                                        Text("Following")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Bio only (username moved to nav bar)
                        if let user = authManager.currentUser,
                           let bio = user.bio {
                            Text(bio)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Edit Profile Button
                        Button(action: { showingEditProfile = true }) {
                            Text("Edit Profile")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 12) // Add spacing between header and profile content
            }
            .refreshable {
                isRefreshing = true
                if let userId = authManager.currentUser?.id {
                    do {
                        try await authManager.refreshUserData(userId: userId)
                    } catch {
                        print("Error refreshing profile: \(error)")
                    }
                }
                isRefreshing = false
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = authManager.currentUser {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .onChange(of: showingEditProfile) { isShowing in
                if !isShowing {
                    Task {
                        if let userId = authManager.currentUser?.id {
                            try? await authManager.refreshUserData(userId: userId)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
} 