import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var token: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var message: String = ""
    @State private var showingAlert = false
    @State private var isSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Check your email")) {
                    Text("We sent a token to your email. Copy and paste it below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Paste Token Here", text: $token)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Create New Password")) {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Section {
                    Button(action: submitReset) {
                        if authManager.isLoading {
                            ProgressView()
                        } else {
                            Text("Reset Password")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.blue)
                    .disabled(token.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
                }
                
                if !message.isEmpty && !isSuccess {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been reset. You can now log in.")
            }
        }
    }
    
    func submitReset() {
        guard newPassword == confirmPassword else {
            message = "Passwords do not match"
            return
        }
        
        Task {
            do {
                _ = try await authManager.resetPassword(token: token, newPassword: newPassword)
                await MainActor.run {
                    isSuccess = true
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isSuccess = false
                }
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView()
            .environmentObject(AuthManager())
    }
}