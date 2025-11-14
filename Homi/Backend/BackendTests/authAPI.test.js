import express from "express";
import jwt from "jsonwebtoken";
import User from "../models/userModel.js";
import { hashPassword, comparePassword } from "../utils/security.js";

const router = express.Router();

// --- Token Generators ---
const generateAccessToken = (userId) => {
  return jwt.sign({ userId }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "15m"
  });
};

const generateRefreshToken = (userId) => {
  return jwt.sign({ userId }, process.env.REFRESH_TOKEN_SECRET, {
    expiresIn: "7d"
  });
};

// --- REGISTER ---
router.post("/register", async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: "Email already in use" });

    const passwordHash = await hashPassword(password);

    const user = await User.create({
      email,
      passwordHash,
      firstName,
      lastName,
      refreshTokens: []
    });

    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    user.refreshTokens.push(refreshToken);
    await user.save();

    res.status(201).json({
      user: { email: user.email, firstName, lastName },
      accessToken,
      refreshToken
    });
  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// --- LOGIN ---
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: "Invalid credentials" });

    const match = await comparePassword(password, user.passwordHash);
    if (!match) return res.status(401).json({ message: "Invalid credentials" });

    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    user.refreshTokens.push(refreshToken);
    await user.save();

    res.status(200).json({
      user: { email: user.email },
      accessToken,
      refreshToken
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// --- REFRESH TOKEN ---
router.post("/refresh", async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken)
      return res.status(400).json({ message: "Missing token" });

    // 1. Validate token exists in DB
    const user = await User.findOne({ refreshTokens: refreshToken });
    if (!user) return res.status(401).json({ message: "Invalid refresh token" });

    // 2. Validate JWT signature
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);
    } catch {
      return res.status(401).json({ message: "Invalid refresh token" });
    }

    // 3. Revoke old token
    user.refreshTokens = user.refreshTokens.filter(t => t !== refreshToken);

    // 4. Generate new tokens
    const newAccessToken = generateAccessToken(decoded.userId);
    const newRefreshToken = generateRefreshToken(decoded.userId);

    // 5. Store new refresh token
    user.refreshTokens.push(newRefreshToken);
    await user.save();

    res.status(200).json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });
  } catch (err) {
    console.error("Refresh error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// --- LOGOUT ---
router.post("/logout", async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ message: "Missing token" });

    const user = await User.findOne({ refreshTokens: refreshToken });
    if (user) {
      user.refreshTokens = user.refreshTokens.filter(t => t !== refreshToken);
      await user.save();
    }

    res.status(200).json({ message: "Logged out" });
  } catch (err) {
    console.error("Logout error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// --- CURRENT USER ---
router.get("/me", async (req, res) => {
  try {
    const auth = req.headers.authorization;
    if (!auth || !auth.startsWith("Bearer "))
      return res.status(401).json({ message: "No token" });

    const token = auth.split(" ")[1];

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
    } catch {
      return res.status(401).json({ message: "Invalid token" });
    }

    const user = await User.findById(decoded.userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    res.status(200).json({
      user: {
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (err) {
    console.error("ME error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
