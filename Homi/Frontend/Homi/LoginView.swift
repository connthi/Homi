import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?
    
    // States for Forgot Password flow
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetConfirmation = false
    @State private var resetConfirmationMessage = ""
    
    // State for Reset Password View (Token Entry)
    @State private var showResetTokenView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            
            // Header
            VStack(spacing: 6) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Sign in to your account")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Input Fields
            VStack(spacing: 18) {
                floatingField(title: "Email Address", icon: "envelope") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                floatingField(title: "Password", icon: "lock") {
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                            }
                        }
                        
                        // Toggle password visibility
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }
                }
            }
            
            // Forgot Password / Token Buttons
            HStack {
                Button("Forgot password?") {
                    resetEmail = email
                    showForgotPassword = true
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color(red: 0.35, green: 0.36, blue: 0.90))
                
                Spacer()
                
                Button("I have a token") {
                    showResetTokenView = true
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Error Display
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                }
                .transition(.opacity)
            }
            
            // Login Button
            Button(action: handleLogin) {
                HStack {
                    Spacer()
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign in").fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.40, green: 0.52, blue: 0.97),
                            Color(red: 0.78, green: 0.49, blue: 0.97)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .foregroundColor(.white)
                .shadow(
                    color: Color(red: 0.40, green: 0.52, blue: 0.97).opacity(0.4),
                    radius: 10,
                    x: 0,
                    y: 8
                )
            }
            .padding(.top, 12)
            .disabled(disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Sheet 1: Input Email for Reset
        .sheet(isPresented: $showForgotPassword) {
            NavigationView {
                VStack(spacing: 24) {
                    Text("Reset Password")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    Text("Enter your email address to receive a password reset link.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Email", text: $resetEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    Button {
                        submitForgotPassword()
                        showForgotPassword = false
                    } label: {
                        Text("Send Link")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(resetEmail.isEmpty)
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showForgotPassword = false
                        }
                    }
                }
            }
        }
        // Sheet 2: Enter Token (ResetPasswordView)
        .sheet(isPresented: $showResetTokenView) {
            ResetPasswordView()
        }
        // Alert: Success Confirmation
        .alert("Check your email", isPresented: $showResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resetConfirmationMessage)
        }
    }
    
    // Disables login button while loading or if fields are empty
    private var disabled: Bool {
        authManager.isLoading || email.isEmpty || password.isEmpty
    }
    
    // Reusable floating label field with system icon
    private func floatingField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.systemGray4))
            )
        }
    }
    
    // Attempts login and reports backend errors
    private func handleLogin() {
        errorMessage = nil
        
        Task {
            do {
                try await authManager.login(email: email, password: password)
            } catch {
                await MainActor.run {
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // Handles the forgot password API call
    private func submitForgotPassword() {
        guard !resetEmail.isEmpty else { return }
        errorMessage = nil
        
        Task {
            do {
                let message = try await authManager.forgotPassword(email: resetEmail)
                await MainActor.run {
                    resetConfirmationMessage = message
                    showResetConfirmation = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}