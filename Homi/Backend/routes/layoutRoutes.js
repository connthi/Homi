import express from "express";
import Layout from "../models/layoutModel.js";
import { authenticate } from "../middleware/authMiddleware.js";

// Create a new Express router to group all layout-related routes
const router = express.Router();

/**
 *  POST /api/layouts
 *  Purpose: Create and save a new room layout
 *  PROTECTED: Requires authentication
 */
router.post("/", authenticate, async (req, res) => {
  try {
    // Create a new Layout document from the request body (JSON data)
    // Associate it with the authenticated user
    const layout = new Layout({
      ...req.body,
      userId: req.user.id  // Ensure layout belongs to authenticated user
    });

    // Save the layout into MongoDB
    await layout.save();

    // Respond with HTTP 201 (Created) and return the saved layout data
    res.status(201).json(layout);
  } catch (error) {
    // If something goes wrong (e.g., validation error), return HTTP 400
    res.status(400).json({ message: error.message });
  }
});

/**
 *  GET /api/layouts
 *  Purpose: Retrieve all saved layouts for the authenticated user
 *  PROTECTED: Requires authentication
 */
router.get("/", authenticate, async (req, res) => {
  try {
    // Fetch only layouts that belong to the authenticated user
    const layouts = await Layout.find({ userId: req.user.id });

    // Return them as JSON
    res.json(layouts);
  } catch (error) {
    // Handle any server/database errors
    res.status(500).json({ message: error.message });
  }
});

/**
 *  GET /api/layouts/:id
 *  Purpose: Retrieve a specific layout by its MongoDB ID
 *  PROTECTED: Requires authentication and ownership
 */
router.get("/:id", authenticate, async (req, res) => {
  try {
    // Search for a layout using the ID in the request URL
    // AND verify it belongs to the authenticated user
    const layout = await Layout.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    // If not found or doesn't belong to user, return a 404 (Not Found)
    if (!layout) return res.status(404).json({ message: "Layout not found" });

    // Otherwise, return the layout as JSON
    res.json(layout);
  } catch (error) {
    // If the ID format is invalid or a DB error occurs, return HTTP 500
    res.status(500).json({ message: error.message });
  }
});

/**
 *  PUT /api/layouts/:id
 *  Purpose: Update an existing layout by ID
 *  PROTECTED: Requires authentication and ownership
 */
router.put("/:id", authenticate, async (req, res) => {
  try {
    // Find the layout by ID AND verify it belongs to the authenticated user
    const layout = await Layout.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!layout) {
      return res.status(404).json({ message: "Layout not found" });
    }

    // Update the layout with new data from the request body
    // Prevent userId from being changed
    const { userId, ...updateData } = req.body;
    const updatedLayout = await Layout.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    // Return the updated layout
    res.json(updatedLayout);
  } catch (error) {
    // If validation fails or ID is invalid, return HTTP 400
    res.status(400).json({ message: error.message });
  }
});

/**
 *  DELETE /api/layouts/:id
 *  Purpose: Remove a layout by its ID
 *  PROTECTED: Requires authentication and ownership
 */
router.delete("/:id", authenticate, async (req, res) => {
  try {
    // Find and delete the layout only if it belongs to the authenticated user
    const layout = await Layout.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!layout) {
      return res.status(404).json({ message: "Layout not found" });
    }

    // Confirm deletion to the client
    res.json({ message: "Layout deleted" });
  } catch (error) {
    // Handle any database or server errors
    res.status(500).json({ message: error.message });
  }
});

// Export the router so it can be mounted in server.js
export default router;