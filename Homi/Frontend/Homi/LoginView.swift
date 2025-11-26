import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(spacing: 6) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Sign in to your account")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
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
            
            Button("Forgot password?") {
                // hook in later
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(Color(red: 0.35, green: 0.36, blue: 0.90))
            
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
                        Text("Sign in")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.52, blue: 0.97),
                        Color(red: 0.78, green: 0.49, blue: 0.97)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .cornerRadius(18)
                .foregroundColor(.white)
                .shadow(color: Color(red: 0.40, green: 0.52, blue: 0.97).opacity(0.4), radius: 10, x: 0, y: 8)
            }
            .padding(.top, 12)
            .disabled(disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var disabled: Bool {
        authManager.isLoading || email.isEmpty || password.isEmpty
    }
    
    private func floatingField<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
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
        LoginView()
            .environmentObject(AuthManager())
    }
}
