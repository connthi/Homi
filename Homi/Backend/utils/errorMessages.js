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
    UNABLE_TO_FETCH_USER: "Unable to fetch user profile"
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
    LAYOUT_DELETED: "Layout deleted"
  }
};

