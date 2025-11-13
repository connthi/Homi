import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?
    @Binding var showRegister: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Access your personalized layouts and catalog.")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 18) {
                    labeledField(title: "Email") {
                        TextField("you@homi.app", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    labeledField(title: "Password") {
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("••••••••", text: $password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                        .textContentType(.password)
                                }
                            }
                            
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        }
                    }
                }
                
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
                
                Button(action: handleLogin) {
                    HStack {
                        Spacer()
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(disabled ? Color.gray.opacity(0.4) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 8)
                }
                .disabled(disabled)
                
                Divider()
                    .padding(.vertical, 4)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRegister = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("New here?")
                            .foregroundColor(.secondary)
                        Text("Create an account")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .scrollIndicators(.never)
    }
    
    private var disabled: Bool {
        authManager.isLoading || email.isEmpty || password.isEmpty
    }
    
    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            content()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
        }
    }
    
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showRegister: .constant(false))
            .environmentObject(AuthManager())
    }
}
