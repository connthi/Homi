import mongoose from "mongoose";

const catalogSchema = new mongoose.Schema({
  name: { type: String, required: true },
  type: { type: String, required: true },
  defaultDimensions: {
    width: { type: Number, required: true },
    height: { type: Number, required: true },
    depth: { type: Number, required: true }
  },
  materialOptions: [{ type: String }],
  imageUrl: { type: String },
  description: { type: String },
  modelFileName: { type: String }
});

// Transform the output to match Swift expectations
catalogSchema.set('toJSON', {
  transform: function(doc, ret) {
    // Convert _id ObjectId to string
    ret._id = ret._id.toString();
    return ret;
  }
});

export default mongoose.model("Catalog", catalogSchema);