import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image Picker
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        profileImage = image
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Profile Information") {
                    TextField("Display Name", text: $displayName)
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving || displayName.isEmpty || username.isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
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
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let user = authManager.currentUser else { return }
        displayName = user.displayName
        username = user.username
        bio = user.bio ?? ""
        
        // Load profile image from URL if available
        if let profileImageUrl = user.profileImageUrl,
           let url = URL(string: profileImageUrl) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            profileImage = image
                        }
                    }
                } catch {
                    print("Error loading profile image: \(error)")
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !displayName.isEmpty && !username.isEmpty else { return }
        
        isSaving = true
        Task {
            do {
                // First, upload the image if there's a new one
                var imageUrl: String?
                if let image = profileImage {
                    // TODO: Implement image upload to storage service
                    // imageUrl = try await uploadImage(image)
                }
                
                // Update the user profile in Firestore
                try await authManager.updateUserData(
                    displayName: displayName,
                    username: username,
                    bio: bio,
                    profileImageUrl: imageUrl
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
} 