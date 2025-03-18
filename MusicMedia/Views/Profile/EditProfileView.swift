import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var permissionsManager: PermissionsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingBannerSheet = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var isLoading = false
    @State private var showingSocialMediaLinks = false
    @State private var showingCropView = false
    @State private var imageToEdit: UIImage?
    @State private var profileImage: UIImage?
    @State private var errorMessage: String?
    @State private var showError = false
    private let storageManager = StorageManager()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let user = authManager.currentUser, let profileImageUrl = user.profileImageUrl {
                            AsyncImage(url: URL(string: profileImageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding(.top, 8)
                        } else {
                            PhotosPicker(selection: $selectedImage,
                                       matching: .images,
                                       photoLibrary: .shared()) {
                                Text("Edit picture")
                                    .foregroundColor(.blue)
                            }
                            .onChange(of: selectedImage) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            imageToEdit = uiImage
                                            showingCropView = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            
            Section {
                TextField("Display Name", text: $displayName)
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                NavigationLink {
                    SocialMediaLinksView()
                } label: {
                    Label("Social Media Links", systemImage: "link")
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarItems(
            leading: Button("Cancel") { dismiss() },
            trailing: Button("Done") { saveChanges() }
        )
        .disabled(isLoading)
        .onAppear {
            if let user = authManager.currentUser {
                displayName = user.displayName
                username = user.username
                bio = user.bio ?? ""
            }
            
            // Check photo library permission on appear
            Task {
                _ = await permissionsManager.requestPhotoLibraryPermissionIfNeeded()
            }
        }
        .sheet(isPresented: $showingCropView) {
            if let image = imageToEdit {
                ImageCropView(
                    initialImage: image,
                    onCrop: { croppedImage in
                        Task {
                            await updateProfileImage(with: croppedImage)
                        }
                        showingCropView = false
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                try await authManager.updateUserProfile(fields: [
                    "displayName": displayName,
                    "username": username,
                    "bio": bio
                ])
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving profile changes: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func updateProfileImage(with image: UIImage) async {
        print("🖼️ Starting profile image update process")
        
        // Wait for a short delay to ensure user data is loaded
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let user = authManager.currentUser else {
            print("❌ Cannot update profile image: No user data available")
            await MainActor.run {
                errorMessage = "Unable to update profile image: User data not loaded"
                showError = true
            }
            return
        }
        
        guard let userId = user.id else {
            print("❌ Cannot update profile image: No user ID available")
            await MainActor.run {
                errorMessage = "Unable to update profile image: Please try signing out and back in"
                showError = true
            }
            return
        }
        
        print("🖼️ Current user ID: \(userId)")
        print("🖼️ Current profile image URL: \(user.profileImageUrl ?? "nil")")
        
        await MainActor.run {
            isLoading = true
            profileImage = image // Show the cropped image immediately
            print("🖼️ Set temporary profile image in UI")
        }
        
        do {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                print("🖼️ Successfully converted image to JPEG data. Size: \(imageData.count) bytes")
                if let imageUrl = try await storageManager.uploadProfileImage(data: imageData, userId: userId) {
                    print("🖼️ Successfully uploaded image to Firebase Storage. URL: \(imageUrl)")
                    try await authManager.updateUserProfile(fields: ["profileImageUrl": imageUrl])
                    print("🖼️ Successfully updated user profile with new image URL")
                    
                    // Force a refresh of the user data
                    print("🖼️ Refreshing user data after profile image update")
                    try await authManager.refreshUserData(userId: userId)
                    print("🖼️ Successfully refreshed user data")
                    print("🖼️ New profile image URL: \(authManager.currentUser?.profileImageUrl ?? "nil")")
                    
                    // Ensure the UI is updated with the new image
                    await MainActor.run {
                        if let user = authManager.currentUser {
                            displayName = user.displayName
                            username = user.username
                            bio = user.bio ?? ""
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to upload image"
                        showError = true
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to process image"
                    showError = true
                }
            }
        } catch {
            print("❌ Error updating profile image: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        await MainActor.run {
            isLoading = false
            print("🖼️ Finished profile image update process")
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView()
            .environmentObject(AuthManager())
            .environmentObject(PermissionsManager())
    }
} 