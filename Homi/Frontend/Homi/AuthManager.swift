import Foundation
import SwiftUI
import Combine

/// Observable object for managing authentication state
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    private let apiService = APIService.shared
    
    init() {
        // Check if user is already authenticated on app launch
        checkAuthenticationStatus()
    }
    
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
    
    func login(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let response = try await apiService.login(email: normalizedEmail, password: password)
            await handleAuthSuccess(response)
        } catch {
            await MainActor.run {
                isLoading = false
            }
            throw error
        }
    }
    
    func register(email: String, password: String, firstName: String?, lastName: String?) async throws {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await apiService.register(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            await handleAuthSuccess(response)
        } catch {
            await MainActor.run {
                isLoading = false
            }
            throw error
        }
    }
    
    func logout() async {
        if let refreshToken = authService.getRefreshToken() {
            do {
                try await apiService.logout(refreshToken: refreshToken)
            } catch {
                print("Logout API call failed: \(error)")
            }
        }
        
        // Clear tokens
        authService.clearTokens()
        
        // Update state on main actor
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
            isLoading = false
        }
    }
    
    func fetchCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("Failed to fetch current user: \(error)")
            // If fetching user fails, user might not be authenticated
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
    
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = authService.getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let response = try await apiService.refreshToken(refreshToken: refreshToken)
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
