import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
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
                        TextField("you@homi.app", text: $email)
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
                .disabled(disabled)
                
                VStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.systemGray4))
                        Text("Or sign in with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.systemGray4))
                    }
                    
                    HStack(spacing: 16) {
                        SocialLoginButton(style: .apple) {
                            // Hook up Sign in with Apple later
                        }
                        SocialLoginButton(style: .google) {
                            // Hook up Google later
                        }
                    }
                }
                
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
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

private struct SocialLoginButton: View {
    enum Style {
        case apple
        case google
    }
    
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                icon
                Text(styleText)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(styleBackground)
            .foregroundColor(styleForeground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var styleText: String {
        switch style {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
    
    private var icon: some View {
        Group {
            switch style {
            case .apple:
                Image(systemName: "applelogo")
            case .google:
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.25, green: 0.45, blue: 0.85), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    Text("G")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.25, green: 0.45, blue: 0.85))
                }
            }
        }
    }
    
    private var styleBackground: Color {
        switch style {
        case .apple:
            return Color.black
        case .google:
            return Color.white
        }
    }
    
    private var styleForeground: Color {
        switch style {
        case .apple:
            return .white
        case .google:
            return .black
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}
