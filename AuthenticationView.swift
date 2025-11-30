import SwiftUI

/// Root authentication view that switches between login and registration.
/// Handles animated transitions and shared styling for the auth screens.
struct AuthenticationView: View {
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                
                // Background gradient applied across the full screen
                LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.52, blue: 0.97),
                        Color(red: 0.62, green: 0.44, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Toggle between login and registration
                        Button(action: toggleMode) {
                            HStack(spacing: 6) {
                                Text(showRegister ? "Have an account?" : "Don’t have an account?")
                                Text(showRegister ? "Log in" : "Create one")
                                    .fontWeight(.semibold)
                            }
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 12)
                        
                        // App title and subheading
                        VStack(spacing: 6) {
                            Text("Homi")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            Text(showRegister ? "Create a new space" : "Welcome Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.top, 4)
                        
                        // Auth form container with transitions
                        ZStack {
                            if showRegister {
                                RegisterView()
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                                        removal: .opacity.combined(with: .move(edge: .leading))
                                    ))
                            } else {
                                LoginView()
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .leading)),
                                        removal: .opacity.combined(with: .move(edge: .trailing))
                                    ))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: 520)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
                        .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    /// Toggles between login and registration views with an animated transition.
    private func toggleMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showRegister.toggle()
        }
    }
}