import Foundation
import SwiftUI
import Combine

/// Manages authentication state, token lifecycle, and communication with the backend API.
/// This class is the single source of truth for login/logout and the current user.
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    private let apiService = APIService.shared
    
    init() {
        // App always starts on login; authentication is checked explicitly.
        isAuthenticated = false
    }
    
    /// Checks whether the user has stored tokens and validates them by fetching the user profile.
    func checkAuthenticationStatus() {
        Task {
            let authenticated = authService.isAuthenticated
            await MainActor.run {
                isAuthenticated = authenticated
            }
            
            if authenticated {
                await fetchCurrentUser()
            }
        }
    }
    
    /// Attempts login using email/password and updates global auth state on success.
    func login(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        
        do {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let response = try await apiService.login(email: normalizedEmail, password: password)
            await handleAuthSuccess(response)
        } catch {
            await MainActor.run { isLoading = false }
            throw error
        }
    }
    
    /// Registers a new user and automatically logs them in on success.
    func register(email: String, password: String, firstName: String?, lastName: String?) async throws {
        await MainActor.run { isLoading = true }
        
        do {
            let response = try await apiService.register(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            await handleAuthSuccess(response)
        } catch {
            await MainActor.run { isLoading = false }
            throw error
        }
    }
    
    /// Sends a forgot password request to the API.
    func forgotPassword(email: String) async throws -> String {
        await MainActor.run { isLoading = true }
        // Ensure loading is set to false regardless of success/failure
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let message = try await apiService.forgotPassword(email: normalizedEmail)
        return message
    }
    
    /// Completes the password reset process.
    func resetPassword(token: String, newPassword: String) async throws -> String {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        return try await apiService.resetPassword(token: token, newPassword: newPassword)
    }
    
    /// Logs the user out, clears local tokens, and resets all authentication state.
    func logout() async {
        if let refreshToken = authService.getRefreshToken() {
            do {
                try await apiService.logout(refreshToken: refreshToken)
            } catch {
                // Logout failures should not block local logout
                print("Logout API call failed: \(error)")
            }
        }
        
        authService.clearTokens()
        
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
            isLoading = false
        }
    }
    
    /// Fetches the authenticated user's profile.  
    /// If unauthorized, the user is automatically logged out.
    func fetchCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("Failed to fetch current user: \(error)")
            
            // Handle invalid/expired tokens
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized:
                    await logout()
                case .serverError(let statusCode, _) where statusCode == 401:
                    await logout()
                default:
                    break
                }
            }
        }
    }
    
    /// Refreshes the access token using the stored refresh token.
    /// Throws if no refresh token is available.
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = authService.getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let response = try await apiService.refreshToken(refreshToken: refreshToken)
        
        // Update stored tokens
        authService.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.user.id
        )
        
        await MainActor.run {
            currentUser = response.user
            isAuthenticated = true
        }
    }
    
    // MARK: - Helpers
    
    /// Shared handler for login + registration success.
    /// Saves tokens and updates published authentication state.
    private func handleAuthSuccess(_ response: AuthResponse) async {
        authService.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.user.id
        )
        
        await MainActor.run {
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        }
    }
}