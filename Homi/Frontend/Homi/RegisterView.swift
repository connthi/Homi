import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    
    private let minimumPasswordLength = 8

    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    // UI state
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            
            // MARK: - Title
            VStack(spacing: 6) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Join Homi to start designing")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // MARK: - Input Fields
            VStack(spacing: 16) {
                modernField(title: "First Name (Optional)", icon: "person",
                            text: $firstName, contentType: .givenName, autocapitalization: .words)
                
                modernField(title: "Last Name (Optional)", icon: "person",
                            text: $lastName, contentType: .familyName, autocapitalization: .words)
                
                modernField(title: "Email Address", icon: "envelope",
                            text: $email, contentType: .emailAddress,
                            keyboard: .emailAddress, autocapitalization: .never)
                
                secureField(title: "Password", text: $password, isVisible: $isPasswordVisible)
                secureField(title: "Confirm Password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)

                // Inline password validation message
                if let inlineMessage = passwordRequirementsMessage {
                    Text(inlineMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // MARK: - Error Banner
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
            
            // MARK: - Register Button
            Button(action: handleRegister) {
                HStack {
                    Spacer()
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(red: 0.24, green: 0.52, blue: 0.96))
                .cornerRadius(18)
                .foregroundColor(.white)
                .shadow(color: Color(red: 0.24, green: 0.52, blue: 0.96).opacity(0.35),
                        radius: 10, x: 0, y: 8)
            }
            .disabled(!isFormValid || authManager.isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= minimumPasswordLength
    }

    private var passwordRequirementsMessage: String? {
        if password.count < minimumPasswordLength {
            return "Password must be at least \(minimumPasswordLength) characters."
        }
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "Passwords must match."
        }
        return nil
    }
    
    // MARK: - Text Field Builder (Modern Style)
    private func modernField(title: String,
                             icon: String,
                             text: Binding<String>,
                             contentType: UITextContentType? = nil,
                             keyboard: UIKeyboardType = .default,
                             autocapitalization: TextInputAutocapitalization = .sentences) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                TextField(title, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalization)
                    .textContentType(contentType)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.systemGray4))
            )
        }
    }
    
    // MARK: - Secure Field Builder
    private func secureField(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.secondary)
                
                Group {
                    if isVisible.wrappedValue {
                        TextField(title, text: text)
                            .textContentType(.newPassword)
                    } else {
                        SecureField(title, text: text)
                            .textContentType(.newPassword)
                    }
                }
                
                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.systemGray4))
            )
        }
    }
    
    // MARK: - Registration Handler
    private func handleRegister() {
        errorMessage = nil
        
        guard isFormValid else {
            errorMessage = "Please make sure all fields are valid and passwords match."
            return
        }
        
        Task {
            do {
                try await authManager.register(
                    email: email,
                    password: password,
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName
                )
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

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthManager())
    }
}