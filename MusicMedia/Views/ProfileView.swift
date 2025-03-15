import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Header
            VStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                if let user = authManager.currentUser {
                    Text(user.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Stats
            HStack(spacing: 40) {
                VStack {
                    Text("\(authManager.currentUser?.followers.count ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Followers")
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(authManager.currentUser?.following.count ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Following")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Sign Out Button
            Button(action: {
                try? authManager.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .navigationTitle("Profile")
    }
} 