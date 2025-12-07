import express from "express";
import User from "../models/userModel.js";
import {
  hashPassword,
  verifyPassword,
  createAccessToken,
  createRefreshToken,
  verifyRefreshToken,
  hashToken,
  createPasswordResetToken
} from "../utils/security.js";
import { authenticate } from "../middleware/authMiddleware.js";
import { ErrorMessages } from "../utils/errorMessages.js";

const router = express.Router();
const MAX_REFRESH_TOKENS = Number(process.env.MAX_REFRESH_TOKENS || 5);

router.post("/register", async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ message: ErrorMessages.AUTH.EMAIL_PASSWORD_REQUIRED });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: ErrorMessages.AUTH.PASSWORD_TOO_SHORT });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });

    if (existingUser) {
      return res.status(409).json({ message: ErrorMessages.AUTH.EMAIL_ALREADY_REGISTERED });
    }

    const passwordHash = await hashPassword(password);
    const user = await User.create({
      email: normalizedEmail,
      passwordHash,
      firstName: firstName?.trim() || undefined,
      lastName: lastName?.trim() || undefined,
      refreshTokens: []
    });

    const response = await buildAuthResponse(user);
    return res.status(201).json(response);
  } catch (error) {
    console.error("Register error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_REGISTER });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ message: ErrorMessages.AUTH.EMAIL_PASSWORD_REQUIRED });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_CREDENTIALS });
    }

    const isValid = await verifyPassword(password, user.passwordHash);

    if (!isValid) {
      return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_CREDENTIALS });
    }

    const response = await buildAuthResponse(user);
    return res.json(response);
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_LOGIN });
  }
});

// POST /api/auth/forgot-password
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body || {};

    if (!email) {
      return res.status(400).json({ message: ErrorMessages.AUTH.EMAIL_REQUIRED });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    // Always return success even if user not found to prevent email enumeration
    if (!user) {
      return res.json({ message: ErrorMessages.SUCCESS.PASSWORD_RESET_LINK_SENT });
    }

    // 1. Generate token and hash
    const { token: resetToken, hash: tokenHash } = createPasswordResetToken();

    // 2. Set token hash and expiration (1 hour)
    user.passwordResetToken = tokenHash;
    user.passwordResetExpires = Date.now() + 3600000; // 1 hour

    await user.save();

    // 3. Send Email
    // TODO: Integrate actual email service here (e.g. Nodemailer)
    // For development, we log the token to the console so you can test it manually
    console.log("---------------------------------------------------------");
    console.log(`PASSWORD RESET FOR: ${user.email}`);
    console.log(`RESET TOKEN (use this in the next step): ${resetToken}`);
    console.log("---------------------------------------------------------");

    return res.json({ message: ErrorMessages.SUCCESS.PASSWORD_RESET_LINK_SENT });
  } catch (error) {
    console.error("Forgot password error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_REQUEST_RESET });
  }
});

// POST /api/auth/reset-password
router.post("/reset-password", async (req, res) => {
  try {
    const { token, newPassword } = req.body || {};

    if (!token || !newPassword) {
      return res.status(400).json({ message: ErrorMessages.AUTH.TOKEN_AND_PASSWORD_REQUIRED });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ message: ErrorMessages.AUTH.PASSWORD_TOO_SHORT });
    }

    // 1. Hash the incoming plaintext token to find it in the database
    // We use the same SHA256 hashing method as used in creation
    const incomingTokenHash = hashToken(token); // Note: Make sure hashToken uses SHA256 or match the algo in createPasswordResetToken

    // However, `hashToken` in security.js uses sha512.
    // `createPasswordResetToken` uses sha256. 
    // To be safe, we should use crypto to hash it manually here to match `createPasswordResetToken` logic, 
    // OR change createPasswordResetToken to use hashToken.
    // Let's rely on the import from security.js which we assume matches.
    
    // IMPORTANT FIX: In step 3 (security.js), I used sha256 for the reset token.
    // The existing hashToken function uses sha512. 
    // To ensure this works, we must hash it exactly how we created it.
    
    // NOTE: For this code to work with the security.js provided above, 
    // we need to perform the hashing manually here or export a verify helper.
    // Let's use the crypto module directly here to ensure it matches the `createPasswordResetToken` logic.
    const crypto = await import("crypto");
    const hashedToken = crypto.default.createHash("sha256").update(token).digest("hex");

    // 2. Find user by matching token hash AND ensuring the token is not expired
    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_OR_EXPIRED_TOKEN });
    }

    // 3. Hash the new password and update user record
    user.passwordHash = await hashPassword(newPassword);

    // 4. Clear the token fields
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;

    // 5. Optional: Clear refresh tokens to force re-login on all devices
    // user.refreshTokens = [];

    await user.save();

    return res.json({ message: ErrorMessages.SUCCESS.PASSWORD_RESET_SUCCESS });

  } catch (error) {
    console.error("Reset password error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_RESET_PASSWORD });
  }
});

router.post("/refresh", async (req, res) => {
  try {
    const { refreshToken } = req.body || {};

    if (!refreshToken) {
      return res.status(400).json({ message: ErrorMessages.AUTH.REFRESH_TOKEN_REQUIRED });
    }

    const payload = verifyRefreshToken(refreshToken);
    const user = await User.findById(payload.sub);

    if (!user) {
      return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_REFRESH_TOKEN });
    }

    if (!isRefreshTokenStored(user, refreshToken)) {
      return res.status(401).json({ message: ErrorMessages.AUTH.REFRESH_TOKEN_REVOKED });
    }

    removeRefreshToken(user, refreshToken);
    const response = await buildAuthResponse(user);
    return res.json(response);
  } catch (error) {
    console.error("Refresh error:", error);
    return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_OR_EXPIRED_REFRESH_TOKEN });
  }
});

router.post("/logout", async (req, res) => {
  const { refreshToken } = req.body || {};

  if (!refreshToken) {
    return res.status(400).json({ message: "refreshToken is required" });
  }

  try {
    const payload = verifyRefreshToken(refreshToken);
    const user = await User.findById(payload.sub);

    if (user) {
      removeRefreshToken(user, refreshToken);
      await user.save();
    }
  } catch (error) {
    // Intentionally swallow errors to keep logout idempotent
  }

  return res.json({ message: ErrorMessages.SUCCESS.LOGGED_OUT });
});

router.get("/me", authenticate, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: ErrorMessages.NOT_FOUND.USER });
    }
    return res.json({ user: formatUser(user) });
  } catch (error) {
    console.error("Fetch current user error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_FETCH_USER });
  }
});

async function buildAuthResponse(user) {
  pruneExpiredTokens(user);

  const accessToken = createAccessToken(user);
  const refreshToken = createRefreshToken(user);

  user.refreshTokens.push({
    tokenHash: hashToken(refreshToken.token),
    expiresAt: new Date(refreshToken.expiresAt * 1000)
  });

  if (user.refreshTokens.length > MAX_REFRESH_TOKENS) {
    user.refreshTokens = user.refreshTokens.slice(-MAX_REFRESH_TOKENS);
  }

  await user.save();

  return {
    tokenType: "Bearer",
    accessToken: accessToken.token,
    refreshToken: refreshToken.token,
    accessTokenExpiresAt: accessToken.expiresAt,
    refreshTokenExpiresAt: refreshToken.expiresAt,
    user: formatUser(user)
  };
}

function pruneExpiredTokens(user) {
  const now = new Date();
  user.refreshTokens = (user.refreshTokens || []).filter((entry) => entry.expiresAt > now);
}

function isRefreshTokenStored(user, refreshToken) {
  const hashedToken = hashToken(refreshToken);
  return (user.refreshTokens || []).some((entry) => entry.tokenHash === hashedToken);
}

function removeRefreshToken(user, refreshToken) {
  const hashedToken = hashToken(refreshToken);
  user.refreshTokens = (user.refreshTokens || []).filter((entry) => entry.tokenHash !== hashedToken);
}

function formatUser(user) {
  return {
    id: user._id.toString(),
    email: user.email,
    firstName: user.firstName ?? null,
    lastName: user.lastName ?? null,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };
}

export default router;