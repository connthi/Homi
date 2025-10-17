import mongoose from "mongoose";

const furnitureSchema = new mongoose.Schema({
  furnitureId: String,
  position: {
    x: Number,
    y: Number,
    z: Number
  },
  rotation: {
    x: Number,
    y: Number,
    z: Number
  },
  scale: {
    x: Number,
    y: Number,
    z: Number
  },
  properties: {
    color: String,
    material: String
  }
});

const layoutSchema = new mongoose.Schema({
  userId: String,
  name: String,
  createdAt: { type: Date, default: Date.now },
  furnitureItems: [furnitureSchema]
});

export default mongoose.model("Layout", layoutSchema);
