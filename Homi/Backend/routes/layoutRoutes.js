import express from "express";
import Layout from "../models/layoutModel.js";

// Create a new Express router to group all layout-related routes
const router = express.Router();

/**
 *  POST /api/layouts
 *  Purpose: Create and save a new room layout
 */
router.post("/", async (req, res) => {
  try {
    // Create a new Layout document from the request body (JSON data)
    const layout = new Layout(req.body);

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
 *  Purpose: Retrieve all saved layouts
 */
router.get("/", async (req, res) => {
  try {
    // Fetch all layouts stored in MongoDB
    const layouts = await Layout.find();

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
 */
router.get("/:id", async (req, res) => {
  try {
    // Search for a layout using the ID in the request URL
    const layout = await Layout.findById(req.params.id);

    // If not found, return a 404 (Not Found)
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
 */
router.put("/:id", async (req, res) => {
  try {
    // Find the layout by ID and update it with new data from the request body
    const layout = await Layout.findByIdAndUpdate(req.params.id, req.body, { new: true });

    // Return the updated layout
    res.json(layout);
  } catch (error) {
    // If validation fails or ID is invalid, return HTTP 400
    res.status(400).json({ message: error.message });
  }
});

/**
 *  DELETE /api/layouts/:id
 *  Purpose: Remove a layout by its ID
 */
router.delete("/:id", async (req, res) => {
  try {
    // Delete the layout from MongoDB by its ID
    await Layout.findByIdAndDelete(req.params.id);

    // Confirm deletion to the client
    res.json({ message: "Layout deleted" });
  } catch (error) {
    // Handle any database or server errors
    res.status(500).json({ message: error.message });
  }
});

// Export the router so it can be mounted in server.js
export default router;