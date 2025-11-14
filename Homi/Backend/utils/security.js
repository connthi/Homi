import crypto from "crypto";
import { promisify } from "util";

const {
  randomBytes,
  createHash,
  createHmac,
  timingSafeEqual,
  pbkdf2
} = crypto;

const pbkdf2Async = promisify(pbkdf2);

// Password hashing config
const PASSWORD_ITERATIONS = Number(process.env.AUTH_PBKDF2_ITERATIONS || 310000);
const PASSWORD_DIGEST = process.env.AUTH_PBKDF2_DIGEST || "sha512";
const PASSWORD_KEY_LENGTH = Number(process.env.AUTH_PBKDF2_KEY_LENGTH || 64);

// JWT-like token config
const ACCESS_TOKEN_TTL = Number(process.env.ACCESS_TOKEN_TTL || 900); // 15 min
const REFRESH_TOKEN_TTL = Number(process.env.REFRESH_TOKEN_TTL || 60 * 60 * 24 * 7); // 7 days
const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET || "dev-access-secret";
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || "dev-refresh-secret";

const JWT_HEADER_ENCODED = base64UrlEncodeBuffer(
  Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" }))
);

/**
 * Hash user passwords using PBKDF2.
 */
export async function hashPassword(password) {
  if (typeof password !== "string" || password.length === 0) {
    throw new Error("Password is required");
  }

  const salt = randomBytes(16).toString("hex");
  const derivedKey = await pbkdf2Async(password, salt, PASSWORD_ITERATIONS, PASSWORD_KEY_LENGTH, PASSWORD_DIGEST);

  return `${PASSWORD_ITERATIONS}:${PASSWORD_DIGEST}:${salt}:${derivedKey.toString("hex")}`;
}

/**
 * Verify a password using PBKDF2.
 */
export async function verifyPassword(password, storedHash) {
  if (!storedHash || typeof storedHash !== "string") {
    return false;
  }

  const parts = storedHash.split(":");
  if (parts.length !== 4) return false;

  const [iterationsStr, digest, salt, originalHash] = parts;
  const iterations = Number(iterationsStr);

  if (!iterations || !digest || !salt || !originalHash) return false;

  const keyLength = Math.floor(originalHash.length / 2);
  const derivedKey = await pbkdf2Async(password, salt, iterations, keyLength, digest);
  const originalBuffer = Buffer.from(originalHash, "hex");

  if (originalBuffer.length !== derivedKey.length) return false;

  return timingSafeEqual(originalBuffer, derivedKey);
}

/**
 * Hash tokens for DB storage.
 */
export function hashToken(token) {
  return createHash("sha512").update(token).digest("hex");
}

/**
 * Create access token.
 */
export function createAccessToken(user) {
  return createSignedToken(
    { sub: user._id.toString(), type: "access" },
    ACCESS_TOKEN_SECRET,
    ACCESS_TOKEN_TTL
  );
}

/**
 * Create refresh token.
 */
export function createRefreshToken(user) {
  return createSignedToken(
    { sub: user._id.toString(), type: "refresh" },
    REFRESH_TOKEN_SECRET,
    REFRESH_TOKEN_TTL
  );
}

/**
 * Verify access token.
 */
export function verifyAccessToken(token) {
  return verifySignedToken(token, ACCESS_TOKEN_SECRET, "access");
}

/**
 * Verify refresh token.
 */
export function verifyRefreshToken(token) {
  return verifySignedToken(token, REFRESH_TOKEN_SECRET, "refresh");
}

/**
 * Create signed tokens using HMAC SHA256.
 */
function createSignedToken(payload, secret, ttlSeconds) {
  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + ttlSeconds;

  const encodedPayload = base64UrlEncodeBuffer(
    Buffer.from(JSON.stringify({ ...payload, iat: issuedAt, exp: expiresAt }))
  );

  const data = `${JWT_HEADER_ENCODED}.${encodedPayload}`;
  const signature = createHmac("sha256", secret).update(data).digest();
  const token = `${data}.${base64UrlEncodeBuffer(signature)}`;

  return { token, expiresAt };
}

/**
 * Verify token signature, expiration, and type.
 */
function verifySignedToken(token, secret, expectedType) {
  if (!token || typeof token !== "string") {
    throw new Error("Token is required");
  }

  const [encodedHeader, encodedPayload, encodedSignature] = token.split(".");
  if (!encodedHeader || !encodedPayload || !encodedSignature) {
    throw new Error("Malformed token");
  }

  if (encodedHeader !== JWT_HEADER_ENCODED) {
    throw new Error("Unsupported token header");
  }

  const data = `${encodedHeader}.${encodedPayload}`;
  const expectedSignature = createHmac("sha256", secret).update(data).digest();
  const providedSignature = base64UrlDecodeToBuffer(encodedSignature);

  if (
    expectedSignature.length !== providedSignature.length ||
    !timingSafeEqual(expectedSignature, providedSignature)
  ) {
    throw new Error("Invalid token signature");
  }

  const payload = JSON.parse(base64UrlDecodeToBuffer(encodedPayload).toString("utf8"));

  if (expectedType && payload.type !== expectedType) {
    throw new Error("Invalid token type");
  }

  if (typeof payload.exp !== "number" || payload.exp * 1000 <= Date.now()) {
    throw new Error("Token expired");
  }

  return payload;
}

/**
 * Base64URL encode.
 */
function base64UrlEncodeBuffer(buffer) {
  return buffer
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

/**
 * Base64URL decode.
 */
function base64UrlDecodeToBuffer(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padLength = (4 - (normalized.length % 4)) % 4;
  const padded = normalized + "=".repeat(padLength);
  return Buffer.from(padded, "base64");
}

/**
 * COMPATIBILITY EXPORT
 * Tests expect comparePassword, so alias it to verifyPassword.
 */
export const comparePassword = verifyPassword;
