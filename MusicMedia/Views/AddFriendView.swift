import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search by username or name", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .onChange(of: searchText) { _ in
                            searchUsers()
                        }
                }
                
                if isSearching {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Section {
                        Text("No users found")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section {
                        ForEach(searchResults) { user in
                            HStack {
                                // Profile Image
                                if let profileImageUrl = user.profileImageUrl,
                                   let url = URL(string: profileImageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.secondary)
                                }
                                
                                // User Info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.body)
                                    Text(user.username)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Add Friend Button
                                if user.isFriend {
                                    Text("Friends")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(20)
                                } else if user.friendRequestSent {
                                    Text("Requested")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(20)
                                } else {
                                    Button(action: { sendFriendRequest(to: user) }) {
                                        Text("Add")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        Task {
            do {
                searchResults = try await authManager.searchUsers(matching: searchText)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSearching = false
        }
    }
    
    private func sendFriendRequest(to user: User) {
        Task {
            do {
                try await authManager.sendFriendRequest(to: user)
                // Update the search results to reflect the sent request
                if let index = searchResults.firstIndex(where: { $0.id == user.id }) {
                    var updatedUser = searchResults[index]
                    // Since friendRequestSent is computed, we'll need to update the underlying data
                    // that determines this state
                    searchResults[index] = updatedUser
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
} 