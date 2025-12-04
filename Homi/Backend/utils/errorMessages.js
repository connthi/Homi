/**
 * Error Message Constants
 * Centralized error messages for consistent API responses
 */
export const ErrorMessages = {
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
  AUTHZ: {
    ADMIN_ACCESS_REQUIRED: "Admin access required"
  },
  NOT_FOUND: {
    USER: "User not found",
    CATALOG_ITEM: "Catalog item not found",
    LAYOUT: "Layout not found"
  },
  SUCCESS: {
    LOGGED_OUT: "Logged out",
    LAYOUT_DELETED: "Layout deleted"
  }
};

