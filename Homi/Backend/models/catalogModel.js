import mongoose from "mongoose";

const catalogSchema = new mongoose.Schema({
  name: String,
  type: String,
  defaultDimensions: {
    width: Number,
    height: Number,
    depth: Number
  },
  materialOptions: [String]
});

export default mongoose.model("Catalog", catalogSchema);
