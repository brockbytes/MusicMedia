import Foundation
import FirebaseStorage
import FirebaseAuth

class StorageManager {
    private let storage = Storage.storage()
    
    func uploadProfileImage(data: Data, userId: String) async throws -> String? {
        print("📤 Starting profile image upload to Firebase Storage")
        print("📤 User ID: \(userId)")
        
        let storageRef = storage.reference()
        
        // Create profile_images directory if it doesn't exist
        let profileImagesRef = storageRef.child("profile_images")
        let profileImageRef = profileImagesRef.child(userId)
        print("📤 Storage path: profile_images/\(userId)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            print("📤 Uploading image data...")
            _ = try await profileImageRef.putDataAsync(data, metadata: metadata)
            print("📤 Image data uploaded successfully")
            
            print("📤 Retrieving download URL...")
            let downloadURL = try await profileImageRef.downloadURL()
            print("📤 Download URL retrieved: \(downloadURL.absoluteString)")
            
            return downloadURL.absoluteString
        } catch let error as StorageError {
            print("❌ Storage error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            throw error
        }
    }
} 