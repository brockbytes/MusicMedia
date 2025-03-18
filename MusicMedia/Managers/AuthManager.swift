import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool
    @Published var authError: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Initialize with current auth state
        self.isAuthenticated = auth.currentUser != nil
        
        if let currentUser = auth.currentUser {
            // Fetch user data immediately
            Task {
                do {
                    try await fetchUserData(userId: currentUser.uid)
                } catch {
                    print("Error fetching initial user data: \(error)")
                    self.isAuthenticated = false
                }
            }
        }
        
        setupAuthStateListener()
        setupSessionRestorationListener()
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAuthStateListener() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, firebaseUser) in
            if let firebaseUser = firebaseUser {
                print("🔐 Auth state changed - User signed in with ID: \(firebaseUser.uid)")
                Task {
                    do {
                        // Set authenticated to false while we fetch user data
                        await MainActor.run {
                            self?.isAuthenticated = false
                        }
                        
                        try await self?.fetchUserData(userId: firebaseUser.uid)
                        
                        // Verify user data was loaded
                        if self?.currentUser != nil {
                            print("✅ Successfully loaded user data after auth state change")
                            await MainActor.run {
                                self?.isAuthenticated = true
                            }
                        } else {
                            print("❌ Failed to load user data after auth state change")
                            await MainActor.run {
                                self?.currentUser = nil
                                self?.isAuthenticated = false
                            }
                        }
                    } catch {
                        print("❌ Error fetching user data after auth state change: \(error)")
                        await MainActor.run {
                            self?.currentUser = nil
                            self?.isAuthenticated = false
                        }
                    }
                }
            } else {
                print("🔐 Auth state changed - User signed out")
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }
    
    private func setupSessionRestorationListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionRestoration(_:)),
            name: NSNotification.Name("UserSessionRestored"),
            object: nil
        )
    }
    
    @objc private func handleSessionRestoration(_ notification: Notification) {
        guard let userId = notification.userInfo?["userId"] as? String else {
            print("❌ Session restoration failed - No user ID provided")
            return
        }
        
        print("🔄 Attempting to restore session for user: \(userId)")
        
        Task {
            do {
                // Set authenticated to false while we restore the session
                await MainActor.run {
                    self.isAuthenticated = false
                }
                
                // Verify the Firebase user is still valid
                guard let firebaseUser = Auth.auth().currentUser,
                      firebaseUser.uid == userId else {
                    print("❌ Session restoration failed - Firebase user is invalid")
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                    return
                }
                
                try await fetchUserData(userId: userId)
                
                // Verify user data was loaded
                if currentUser != nil {
                    print("✅ Successfully restored session")
                    await MainActor.run {
                        self.isAuthenticated = true
                    }
                } else {
                    print("❌ Session restoration failed - Could not load user data")
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            } catch {
                print("❌ Error restoring session: \(error)")
                await MainActor.run {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        do {
            // Check if username is available
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            guard snapshot.documents.isEmpty else {
                throw AuthError.usernameAlreadyExists
            }
            
            // Create Firebase Auth user
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let userId = authResult.user.uid
            
            // Create user document
            let user = User(username: username, email: email, displayName: displayName)
            try await db.collection("users").document(userId).setData(from: user)
            
            // Fetch complete user data
            try await fetchUserData(userId: userId)
            isAuthenticated = true
            
        } catch {
            authError = error
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            // Ensure user data is fetched before marking as authenticated
            try await fetchUserData(userId: result.user.uid)
            
            // Double check that the user data was properly loaded
            guard currentUser != nil else {
                throw AuthError.userDataNotFound
            }
            
            print("✅ Successfully signed in and loaded user data")
            print("👤 Current user state:")
            print("👤 - User ID: \(result.user.uid)")
            print("👤 - Display Name: \(currentUser?.displayName ?? "nil")")
            print("👤 - Username: \(currentUser?.username ?? "nil")")
            
            isAuthenticated = true
        } catch {
            authError = error
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            // Clear user data first
            currentUser = nil
            isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: "lastSignedInUser")
            
            // Sign out from Firebase
            try auth.signOut()
            
            print("👋 User signed out successfully")
        } catch {
            print("❌ Error signing out: \(error)")
            authError = error
            throw error
        }
    }
    
    private func fetchUserData(userId: String) async throws {
        print("👤 Fetching user data for userId: \(userId)")
        do {
            let documentSnapshot = try await db.collection("users").document(userId).getDocument()
            guard let data = documentSnapshot.data() else {
                print("❌ No user data found for userId: \(userId)")
                throw AuthError.userDataNotFound
            }
            print("👤 Successfully retrieved user data from Firestore")
            print("👤 Raw user data: \(data)")
            
            let decoder = Firestore.Decoder()
            var user = try decoder.decode(User.self, from: data)
            // Explicitly set the document ID since @DocumentID might not be working correctly
            user.id = userId
            currentUser = user
            
            print("👤 Successfully decoded user data:")
            print("👤 - User ID: \(currentUser?.id ?? "nil")")
            print("👤 - Display Name: \(currentUser?.displayName ?? "nil")")
            print("👤 - Username: \(currentUser?.username ?? "nil")")
            print("👤 - Profile Image URL: \(currentUser?.profileImageUrl ?? "nil")")
        } catch {
            print("❌ Error fetching user data: \(error)")
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    func updateUserData(displayName: String, username: String, bio: String?, profileImageUrl: String?) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.userDataNotFound
        }
        
        // Check if the new username is available (if it's different from current)
        if let currentUser = currentUser, username != currentUser.username {
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            guard snapshot.documents.isEmpty else {
                throw AuthError.usernameAlreadyExists
            }
        }
        
        // Update the user document
        var updateData: [String: Any] = [
            "displayName": displayName,
            "username": username
        ]
        
        if let bio = bio {
            updateData["bio"] = bio
        }
        
        if let profileImageUrl = profileImageUrl {
            updateData["profileImageUrl"] = profileImageUrl
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
        
        // Fetch updated user data
        try await fetchUserData(userId: userId)
    }
    
    func updateUserProfile(fields: [String: Any]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found when trying to update profile")
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        print("👤 Updating user profile for userId: \(userId)")
        print("👤 Fields to update: \(fields)")
        
        do {
            try await db.collection("users").document(userId).updateData(fields)
            print("👤 Successfully updated user profile in Firestore")
            
            // Fetch the updated user data
            try await fetchUserData(userId: userId)
            print("👤 Profile update complete. Current user state:")
            print("👤 - Display Name: \(currentUser?.displayName ?? "nil")")
            print("👤 - Username: \(currentUser?.username ?? "nil")")
            print("👤 - Profile Image URL: \(currentUser?.profileImageUrl ?? "nil")")
        } catch {
            print("❌ Error updating user profile: \(error)")
            throw error
        }
    }
    
    // MARK: - Friend Management
    
    func searchUsers(matching query: String) async throws -> [User] {
        guard !query.isEmpty else { return [] }
        
        let usersRef = db.collection("users")
        let querySnapshot = try await usersRef
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        return try querySnapshot.documents.compactMap { document in
            try document.data(as: User.self)
        }
    }
    
    func sendFriendRequest(to user: User) async throws {
        guard let currentUserId = auth.currentUser?.uid,
              let targetUserId = user.id else {
            throw AuthError.userDataNotFound
        }
        
        // Create friend request document
        let requestData: [String: Any] = [
            "fromUserId": currentUserId,
            "toUserId": targetUserId,
            "status": "pending",
            "timestamp": Timestamp()
        ]
        
        try await db.collection("friendRequests").addDocument(data: requestData)
    }
    
    func acceptFriendRequest(from userId: String) async throws {
        guard let currentUserId = auth.currentUser?.uid else {
            throw AuthError.userDataNotFound
        }
        
        // Update friend request status
        let requestSnapshot = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        guard let requestDoc = requestSnapshot.documents.first else {
            throw AuthError.unknown
        }
        
        // Update request status
        try await requestDoc.reference.updateData(["status": "accepted"])
        
        // Add users to each other's friends lists
        let batch = db.batch()
        let currentUserRef = db.collection("users").document(currentUserId)
        let otherUserRef = db.collection("users").document(userId)
        
        batch.updateData([
            "following": FieldValue.arrayUnion([userId])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followers": FieldValue.arrayUnion([currentUserId])
        ], forDocument: otherUserRef)
        
        try await batch.commit()
    }
    
    func rejectFriendRequest(from userId: String) async throws {
        guard let currentUserId = auth.currentUser?.uid else {
            throw AuthError.userDataNotFound
        }
        
        let requestSnapshot = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        guard let requestDoc = requestSnapshot.documents.first else {
            throw AuthError.unknown
        }
        
        try await requestDoc.reference.updateData(["status": "rejected"])
    }
    
    func removeFriend(_ userId: String) async throws {
        guard let currentUserId = auth.currentUser?.uid else {
            throw AuthError.userDataNotFound
        }
        
        let batch = db.batch()
        let currentUserRef = db.collection("users").document(currentUserId)
        let otherUserRef = db.collection("users").document(userId)
        
        batch.updateData([
            "following": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followers": FieldValue.arrayRemove([currentUserId])
        ], forDocument: otherUserRef)
        
        try await batch.commit()
    }
    
    func refreshUserData(userId: String) async throws {
        try await fetchUserData(userId: userId)
    }
}

enum AuthError: LocalizedError {
    case usernameAlreadyExists
    case userDataNotFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .usernameAlreadyExists:
            return "Username is already taken"
        case .userDataNotFound:
            return "User data not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 