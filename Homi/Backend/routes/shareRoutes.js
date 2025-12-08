import express from "express";
import Layout from "../models/layoutModel.js";
import Share from "../models/shareModel.js";
import { authenticate } from "../middleware/authMiddleware.js";
import crypto from "crypto";

const router = express.Router();

/**
 * POST /api/share
 * Purpose: Create a shareable link for a layout
 * PROTECTED: Requires authentication
 */
router.post("/", authenticate, async (req, res) => {
  try {
    const { layoutId } = req.body;

    if (!layoutId) {
      return res.status(400).json({ message: "layoutId is required" });
    }

    // Verify the layout exists and belongs to the user
    const layout = await Layout.findOne({
      _id: layoutId,
      userId: req.user.id
    });

    if (!layout) {
      return res.status(404).json({ 
        message: "Layout not found or you don't have permission to share it" 
      });
    }

    // Check if a share link already exists for this layout
    let share = await Share.findOne({ layoutId });

    if (!share) {
      // Generate a unique share ID (8 characters, URL-safe)
      const shareId = crypto.randomBytes(6).toString("base64url");

      // Create new share record
      share = new Share({
        shareId,
        layoutId,
        createdBy: req.user.id,
        // Optional: Set expiration (e.g., 30 days from now)
        // expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      });

      await share.save();
    }

    // Return the share information
    res.status(201).json({
      shareId: share.shareId,
      shareUrl: `https://homi.app/view/${share.shareId}`,
      createdAt: share.createdAt,
      expiresAt: share.expiresAt
    });
  } catch (error) {
    console.error("Error creating share link:", error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /api/share/:shareId
 * Purpose: Retrieve a shared layout (PUBLIC - no auth required)
 */
router.get("/:shareId", async (req, res) => {
  try {
    const { shareId } = req.params;

    // Find the share record
    const share = await Share.findOne({ shareId });

    if (!share) {
      return res.status(404).json({ 
        message: "Shared layout not found or has expired" 
      });
    }

    // Check if expired
    if (share.expiresAt && share.expiresAt < new Date()) {
      return res.status(410).json({ 
        message: "This share link has expired" 
      });
    }

    // Fetch the actual layout
    const layout = await Layout.findById(share.layoutId);

    if (!layout) {
      return res.status(404).json({ 
        message: "Layout not found" 
      });
    }

    // Increment view count
    share.viewCount += 1;
    await share.save();

    // Return the layout (without exposing the owner's userId)
    const sanitizedLayout = {
      _id: layout._id.toString(),
      name: layout.name,
      createdAt: layout.createdAt,
      furnitureItems: layout.furnitureItems,
      // Do NOT include userId for privacy
    };

    res.json(sanitizedLayout);
  } catch (error) {
    console.error("Error fetching shared layout:", error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * DELETE /api/share/:shareId
 * Purpose: Revoke/delete a share link
 * PROTECTED: Requires authentication
 */
router.delete("/:shareId", authenticate, async (req, res) => {
  try {
    const { shareId } = req.params;

    // Find and verify ownership
    const share = await Share.findOne({ shareId });

    if (!share) {
      return res.status(404).json({ message: "Share link not found" });
    }

    // Verify the user owns the original layout
    const layout = await Layout.findOne({
      _id: share.layoutId,
      userId: req.user.id
    });

    if (!layout) {
      return res.status(403).json({ 
        message: "You don't have permission to delete this share link" 
      });
    }

    // Delete the share
    await Share.deleteOne({ shareId });

    res.json({ message: "Share link deleted successfully" });
  } catch (error) {
    console.error("Error deleting share link:", error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /api/share
 * Purpose: Get all share links created by the authenticated user
 * PROTECTED: Requires authentication
 */
router.get("/", authenticate, async (req, res) => {
  try {
    const shares = await Share.find({ createdBy: req.user.id })
      .populate("layoutId", "name createdAt")
      .sort({ createdAt: -1 });

    const shareList = shares.map(share => ({
      shareId: share.shareId,
      shareUrl: `https://homi.app/view/${share.shareId}`,
      layoutName: share.layoutId?.name || "Unknown Layout",
      createdAt: share.createdAt,
      expiresAt: share.expiresAt,
      viewCount: share.viewCount
    }));

    res.json(shareList);
  } catch (error) {
    console.error("Error fetching share links:", error);
    res.status(500).json({ message: error.message });
  }
});

export default router;