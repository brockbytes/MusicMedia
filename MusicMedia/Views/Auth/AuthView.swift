import SwiftUI

struct AuthView: View {
    @State private var isShowingLogin = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and App Name
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("MusicMedia")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 40)
                    
                    // Auth Form
                    if isShowingLogin {
                        LoginView()
                    } else {
                        SignUpView()
                    }
                    
                    // Toggle Button
                    Button(action: { isShowingLogin.toggle() }) {
                        Text(isShowingLogin ? "New user? Create an account" : "Already have an account? Sign in")
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 8)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || !isValidInput)
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: signUp) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create Account")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || !isValidInput)
        }
        .padding(.horizontal)
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        !displayName.isEmpty && password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signUp(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName
                )
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
} 