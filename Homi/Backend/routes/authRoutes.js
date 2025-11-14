import express from "express";
import User from "../models/userModel.js";
import {
  hashPassword,
  verifyPassword,
  createAccessToken,
  createRefreshToken,
  verifyRefreshToken,
  hashToken
} from "../utils/security.js";
import { authenticate } from "../middleware/authMiddleware.js";

const router = express.Router();
const MAX_REFRESH_TOKENS = Number(process.env.MAX_REFRESH_TOKENS || 5);

router.post("/register", async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: "Password must be at least 8 characters" });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });

    if (existingUser) {
      return res.status(409).json({ message: "Email is already registered" });
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
    return res.status(500).json({ message: "Unable to register user" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const isValid = await verifyPassword(password, user.passwordHash);

    if (!isValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const response = await buildAuthResponse(user);
    return res.json(response);
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "Unable to login" });
  }
});

router.post("/refresh", async (req, res) => {
  try {
    const { refreshToken } = req.body || {};

    if (!refreshToken) {
      return res.status(400).json({ message: "refreshToken is required" });
    }

    const payload = verifyRefreshToken(refreshToken);
    const user = await User.findById(payload.sub);

    if (!user) {
      return res.status(401).json({ message: "Invalid refresh token" });
    }

    if (!isRefreshTokenStored(user, refreshToken)) {
      return res.status(401).json({ message: "Refresh token has been revoked" });
    }

    removeRefreshToken(user, refreshToken);
    const response = await buildAuthResponse(user);
    return res.json(response);
  } catch (error) {
    console.error("Refresh error:", error);
    return res.status(401).json({ message: "Invalid or expired refresh token" });
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

  return res.json({ message: "Logged out" });
});

router.get("/me", authenticate, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    return res.json({ user: formatUser(user) });
  } catch (error) {
    console.error("Fetch current user error:", error);
    return res.status(500).json({ message: "Unable to fetch user profile" });
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
