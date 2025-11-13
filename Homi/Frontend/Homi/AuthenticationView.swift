import SwiftUI

struct AuthenticationView: View {
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.13, blue: 0.25),
                        Color(red: 0.03, green: 0.03, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 20) {
                        Text(showRegister ? "Create Account" : "Welcome Back")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            authToggleButton(title: "Login", isActive: !showRegister) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showRegister = false
                                }
                            }
                            
                            authToggleButton(title: "Create Account", isActive: showRegister) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showRegister = true
                                }
                            }
                        }
                        
                        Divider()
                        
                        ZStack {
                            if showRegister {
                                RegisterView(showLogin: registerBinding)
                                    .transition(.opacity)
                            } else {
                                LoginView(showRegister: $showRegister)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 520)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 20)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func authToggleButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isActive ? Color.white : Color.white.opacity(0.08))
                )
                .foregroundColor(isActive ? .black : .white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: isActive ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var registerBinding: Binding<Bool> {
        Binding(
            get: { !showRegister },
            set: { newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showRegister = !newValue
                }
            }
        )
    }
}
