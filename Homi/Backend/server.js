// server.js
import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";

import layoutRoutes from "./routes/layoutRoutes.js";
import catalogRoutes from "./routes/catalogRoutes.js";

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());

// Routes
app.use("/api/layouts", layoutRoutes);
app.use("/api/catalog", catalogRoutes);

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

if (process.env.NODE_ENV !== "test") {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
}

export default app;