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

// Transform the output to match Swift expectations
layoutSchema.set('toJSON', {
  transform: function(doc, ret) {
    // Convert _id to string for Swift
    ret._id = ret._id.toString();
    
    // Transform nested furniture items
    if (ret.furnitureItems) {
      ret.furnitureItems = ret.furnitureItems.map(item => ({
        _id: item._id.toString(),
        furnitureId: item.furnitureId,
        position: item.position,
        rotation: item.rotation,
        scale: item.scale,
        properties: item.properties
      }));
    }
    
    return ret;
  }
});

export default mongoose.model("Layout", layoutSchema);
