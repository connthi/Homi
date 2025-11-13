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

// Routes
app.use("/api/layouts", layoutRoutes);
app.use("/api/catalog", catalogRoutes);
app.use("/api/auth", authRoutes);

async function connectToDatabase(uri = process.env.MONGO_URI) {
  if (!uri) {
    throw new Error("MONGO_URI is not defined");
  }

  if (mongoose.connection.readyState !== 0) {
    return;
  }

  console.log("Connecting to Mongo:", uri);
  await mongoose.connect(uri);
  console.log("MongoDB connected");
}

if (process.env.NODE_ENV !== "test") {
  connectToDatabase().catch((err) => {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  });

  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
}

export { connectToDatabase };

export default app;
