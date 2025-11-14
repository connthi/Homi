import SwiftUI

struct AuthenticationView: View {
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.52, blue: 0.97),
                        Color(red: 0.62, green: 0.44, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    Spacer().frame(height: 24)
                    
                    Button(action: toggleMode) {
                        HStack(spacing: 6) {
                            Text(showRegister ? "Have an account?" : "Don’t have an account?")
                            Text(showRegister ? "Log in" : "Create one")
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    
                    VStack(spacing: 6) {
                        Text("Homi")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text(showRegister ? "Create a new space" : "Welcome Back")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 8)
                    
                    ZStack {
                        if showRegister {
                            RegisterView()
                                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),
                                                        removal: .opacity.combined(with: .move(edge: .leading))))
                        } else {
                            LoginView()
                                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)),
                                                        removal: .opacity.combined(with: .move(edge: .trailing))))
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 28)
                    .frame(maxWidth: 500)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.2), radius: 25, x: 0, y: 20)
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func toggleMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showRegister.toggle()
        }
    }
}
