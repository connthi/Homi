/**
 * Centralized error messages for consistent API responses
 * This ensures all error messages follow the same format and can be easily updated
 */

export const ErrorMessages = {
  // Authentication errors
  AUTH: {
    EMAIL_PASSWORD_REQUIRED: "Email and password are required",
    PASSWORD_TOO_SHORT: "Password must be at least 8 characters",
    EMAIL_ALREADY_REGISTERED: "Email is already registered",
    INVALID_CREDENTIALS: "Invalid credentials",
    REFRESH_TOKEN_REQUIRED: "refreshToken is required",
    INVALID_REFRESH_TOKEN: "Invalid refresh token",
    REFRESH_TOKEN_REVOKED: "Refresh token has been revoked",
    INVALID_OR_EXPIRED_REFRESH_TOKEN: "Invalid or expired refresh token",
    UNABLE_TO_REGISTER: "Unable to register user",
    UNABLE_TO_LOGIN: "Unable to login",
    UNABLE_TO_FETCH_USER: "Unable to fetch user profile",
    // New Forgot Password Errors
    EMAIL_REQUIRED: "Email is required",
    TOKEN_AND_PASSWORD_REQUIRED: "Token and new password are required",
    INVALID_OR_EXPIRED_TOKEN: "Password reset token is invalid or has expired",
    UNABLE_TO_REQUEST_RESET: "Unable to process password reset request",
    UNABLE_TO_RESET_PASSWORD: "Unable to reset password"
  },

  // Authorization errors
  AUTHZ: {
    ADMIN_ACCESS_REQUIRED: "Admin access required"
  },

  // Resource not found errors
  NOT_FOUND: {
    USER: "User not found",
    LAYOUT: "Layout not found",
    CATALOG_ITEM: "Catalog item not found"
  },

  // Success messages
  SUCCESS: {
    LOGGED_OUT: "Logged out",
    LAYOUT_DELETED: "Layout deleted",
    // New Success Messages
    PASSWORD_RESET_LINK_SENT: "If an account with that email exists, we have sent a password reset link.",
    PASSWORD_RESET_SUCCESS: "Password has been successfully reset."
  }
};