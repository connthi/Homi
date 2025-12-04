/**
 * HTTP Status Code Constants
 * Centralized status codes for consistent API responses
 */
export const HTTP_STATUS = {
  // Success
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  
  // Client Errors
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  
  // Server Errors
  INTERNAL_SERVER_ERROR: 500
};

