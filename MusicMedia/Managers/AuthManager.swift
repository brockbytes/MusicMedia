import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task {
                if let firebaseUser = user {
                    try? await self?.fetchUserData(userId: firebaseUser.uid)
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
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
            try await fetchUserData(userId: result.user.uid)
            isAuthenticated = true
        } catch {
            authError = error
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            authError = error
            throw error
        }
    }
    
    private func fetchUserData(userId: String) async throws {
        let documentSnapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = documentSnapshot.data() else {
            throw AuthError.userDataNotFound
        }
        currentUser = try Firestore.Decoder().decode(User.self, from: data)
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