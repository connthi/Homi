// server.js
import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";

import layoutRoutes from "./routes/layoutRoutes.js";
import catalogRoutes from "./routes/catalogRoutes.js";
import authRoutes from "./routes/authRoutes.js";

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());

// ----------------------
// ROUTES
// ----------------------
app.use("/api/auth", authRoutes);
app.use("/api/layouts", layoutRoutes);
app.use("/api/catalog", catalogRoutes);

// ----------------------
// DATABASE CONNECTION (SKIPPED IN TESTS)
// ----------------------
if (process.env.NODE_ENV !== "test") {
  console.log("Connecting to Mongo:", process.env.MONGO_URI);

  mongoose
    .connect(process.env.MONGO_URI)
    .then(() => console.log("MongoDB connected"))
    .catch((err) => console.error("MongoDB connection error:", err));

  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
}

// DO NOT CONNECT OR LISTEN DURING TESTS
export default app;
