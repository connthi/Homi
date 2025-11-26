import express from "express";
import Catalog from "../models/catalogModel.js";
import { authenticate } from "../middleware/authMiddleware.js";
import { ErrorMessages } from "../utils/errorMessages.js";

// Create a new Express router instance
const router = express.Router();

/**
 *  GET /api/catalog
 *  Purpose: Retrieve all catalog items from the database
 *  PUBLIC: Anyone can view the furniture catalog 
 */
router.get("/", async (req, res) => {
  try {
    // Fetch all catalog items stored in MongoDB
    const catalog = await Catalog.find();

    // Send the catalog data as a JSON response
    res.json(catalog);
  } catch (error) {
    // If something goes wrong (e.g., database error), send HTTP 500
    res.status(500).json({ message: error.message });
  }
});

/**
 *  POST /api/catalog
 *  Purpose: Add a new catalog item to the database
 *  PROTECTED: Requires authentication
 */
router.post("/", authenticate, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ message: ErrorMessages.AUTHZ.ADMIN_ACCESS_REQUIRED });
    }

    // Create a new Catalog document using data from the request body
    const item = new Catalog(req.body);

    // Save the new item to MongoDB
    await item.save();

    // Respond with HTTP 201 (Created) and return the saved item
    res.status(201).json(item);
  } catch (error) {
    // If validation fails or bad input is given, respond with HTTP 400
    res.status(400).json({ message: error.message });
  }
});

/**
 *  PUT /api/catalog/:id
 *  Purpose: Update an existing catalog item
 *  PROTECTED: Requires authentication
 */
router.put("/:id", authenticate, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ message: ErrorMessages.AUTHZ.ADMIN_ACCESS_REQUIRED });
    }

    const item = await Catalog.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!item) {
      return res.status(404).json({ message: ErrorMessages.NOT_FOUND.CATALOG_ITEM });
    }

    res.json(item);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Export this router so it can be used in server.js
export default router;