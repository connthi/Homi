import mongoose from "mongoose";

const shareSchema = new mongoose.Schema({
  shareId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  layoutId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Layout",
    required: true
  },
  createdBy: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  expiresAt: {
    type: Date,
    default: null // null means never expires
  },
  viewCount: {
    type: Number,
    default: 0
  }
});

// Index for automatic expiration
shareSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model("Share", shareSchema);