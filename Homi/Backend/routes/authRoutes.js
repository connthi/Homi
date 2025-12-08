import express from "express";
import nodemailer from "nodemailer";
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

// POST /api/auth/register
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

// POST /api/auth/login
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
// POST /api/auth/forgot-password
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body || {};

    if (!email) {
      return res.status(400).json({ message: ErrorMessages.AUTH.EMAIL_REQUIRED });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    // 1. If user doesn't exist, return success anyway (security best practice)
    if (!user) {
      return res.json({ message: ErrorMessages.SUCCESS.PASSWORD_RESET_LINK_SENT });
    }

    // 2. Generate token and hash
    const { token: resetToken, hash: tokenHash } = createPasswordResetToken();

    // 3. Save hash to database
    user.passwordResetToken = tokenHash;
    user.passwordResetExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // 4. Send Email via Gmail
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const mailOptions = {
      from: `"Homi Support" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: "Reset your Homi password",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #4A90E2;">Password Reset Request</h2>
          <p>You requested to reset your password for Homi.</p>
          
          <p><strong>Step 1:</strong> Copy the security token below:</p>
          
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 8px; border: 1px solid #ddd; font-family: monospace; font-size: 16px; margin: 20px 0; word-break: break-all; color: #333;">
            ${resetToken}
          </div>
          
          <p><strong>Step 2:</strong> Open the Homi app, tap <b>"I have a token"</b> on the login screen, and paste the code above.</p>
          
          <p style="color: #666; font-size: 12px; margin-top: 30px;">This token expires in 1 hour. If you did not request this, please ignore this email.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log(`Email sent to ${user.email}`);

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

    // 1. Hash the incoming token to match what is stored in DB
    const crypto = await import("crypto");
    const hashedToken = crypto.default.createHash("sha256").update(token).digest("hex");

    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(401).json({ message: ErrorMessages.AUTH.INVALID_OR_EXPIRED_TOKEN });
    }

    // 2. Update Password
    user.passwordHash = await hashPassword(newPassword);
    
    // 3. Clear Reset Fields
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;

    await user.save();

    return res.json({ message: ErrorMessages.SUCCESS.PASSWORD_RESET_SUCCESS });

  } catch (error) {
    console.error("Reset password error:", error);
    return res.status(500).json({ message: ErrorMessages.AUTH.UNABLE_TO_RESET_PASSWORD });
  }
});

// POST /api/auth/refresh
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

// POST /api/auth/logout
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

// GET /api/auth/me
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

// --- HELPER FUNCTIONS ---

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