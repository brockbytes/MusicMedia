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
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                Task {
                    do {
                        try await self?.fetchUserData(userId: firebaseUser.uid)
                        await MainActor.run {
                            self?.isAuthenticated = true
                        }
                    } catch {
                        print("Error fetching user data: \(error)")
                        await MainActor.run {
                            self?.currentUser = nil
                            self?.isAuthenticated = false
                        }
                    }
                }
            } else {
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
        guard let userId = notification.userInfo?["userId"] as? String else { return }
        
        Task {
            do {
                try await fetchUserData(userId: userId)
                await MainActor.run {
                    self.isAuthenticated = true
                }
            } catch {
                print("Error restoring user session: \(error)")
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