import mongoose from "mongoose";
import dotenv from "dotenv";
import Catalog from "./models/catalogModel.js";
import Layout from "./models/layoutModel.js";

dotenv.config();

// Realistic furniture catalog with proper dimensions (in meters) and image URLs
const realisticFurniture = [
  // SOFAS
  {
    name: "Modern L-Shaped Sectional",
    type: "Sofa",
    defaultDimensions: { width: 2.5, height: 0.85, depth: 1.6 },
    materialOptions: ["fabric", "leather", "velvet"],
    imageUrl: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400",
    description: "Spacious sectional perfect for large living rooms"
  },
  {
    name: "Classic Three-Seater Sofa",
    type: "Sofa",
    defaultDimensions: { width: 2.1, height: 0.8, depth: 0.9 },
    materialOptions: ["fabric", "leather", "linen"],
    imageUrl: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400",
    description: "Traditional comfort for any living space"
  },
  {
    name: "Compact Loveseat",
    type: "Sofa",
    defaultDimensions: { width: 1.5, height: 0.75, depth: 0.85 },
    materialOptions: ["fabric", "microfiber"],
    imageUrl: "https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=400",
    description: "Perfect for small apartments"
  },

  // CHAIRS
  {
    name: "Ergonomic Office Chair",
    type: "Chair",
    defaultDimensions: { width: 0.65, height: 1.1, depth: 0.65 },
    materialOptions: ["mesh", "leather"],
    imageUrl: "https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=400",
    description: "Adjustable lumbar support for work from home"
  },
  {
    name: "Modern Dining Chair",
    type: "Chair",
    defaultDimensions: { width: 0.45, height: 0.85, depth: 0.5 },
    materialOptions: ["wood", "metal", "plastic"],
    imageUrl: "https://images.unsplash.com/photo-1503602642458-232111445657?w=400",
    description: "Sleek design for contemporary dining"
  },
  {
    name: "Accent Armchair",
    type: "Chair",
    defaultDimensions: { width: 0.8, height: 0.9, depth: 0.85 },
    materialOptions: ["velvet", "linen", "leather"],
    imageUrl: "https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=400",
    description: "Statement piece for living room"
  },
  {
    name: "Rocking Chair",
    type: "Chair",
    defaultDimensions: { width: 0.7, height: 1.0, depth: 0.9 },
    materialOptions: ["wood", "rattan"],
    imageUrl: "https://images.unsplash.com/photo-1598300188706-4965b153c07d?w=400",
    description: "Classic comfort with gentle motion"
  },

  // TABLES
  {
    name: "Large Dining Table",
    type: "Table",
    defaultDimensions: { width: 2.0, height: 0.75, depth: 1.0 },
    materialOptions: ["wood", "glass", "marble"],
    imageUrl: "https://images.unsplash.com/photo-1617806118233-18e1de247200?w=400",
    description: "Seats 6-8 people comfortably"
  },
  {
    name: "Round Coffee Table",
    type: "Table",
    defaultDimensions: { width: 1.0, height: 0.45, depth: 1.0 },
    materialOptions: ["wood", "glass", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1611269154421-4e27233ac5c7?w=400",
    description: "Central piece for living room"
  },
  {
    name: "Side Table",
    type: "Table",
    defaultDimensions: { width: 0.5, height: 0.6, depth: 0.5 },
    materialOptions: ["wood", "metal", "glass"],
    imageUrl: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400",
    description: "Perfect beside sofa or bed"
  },
  {
    name: "Console Table",
    type: "Table",
    defaultDimensions: { width: 1.2, height: 0.8, depth: 0.35 },
    materialOptions: ["wood", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=400",
    description: "Elegant hallway or entryway piece"
  },

  // BEDS
  {
    name: "King Size Bed",
    type: "Bed",
    defaultDimensions: { width: 1.93, height: 0.6, depth: 2.03 },
    materialOptions: ["wood", "upholstered", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400",
    description: "Luxurious space for two"
  },
  {
    name: "Queen Size Bed",
    type: "Bed",
    defaultDimensions: { width: 1.52, height: 0.55, depth: 2.03 },
    materialOptions: ["wood", "upholstered"],
    imageUrl: "https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=400",
    description: "Perfect for master bedroom"
  },
  {
    name: "Twin Bed",
    type: "Bed",
    defaultDimensions: { width: 0.99, height: 0.5, depth: 1.91 },
    materialOptions: ["wood", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1505693314120-0d443867891c?w=400",
    description: "Ideal for kids or guest room"
  },

  // STORAGE
  {
    name: "Wardrobe Closet",
    type: "Storage",
    defaultDimensions: { width: 1.5, height: 2.0, depth: 0.6 },
    materialOptions: ["wood", "laminate"],
    imageUrl: "https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=400",
    description: "Ample storage for clothes"
  },
  {
    name: "Bookshelf Unit",
    type: "Storage",
    defaultDimensions: { width: 0.8, height: 1.8, depth: 0.3 },
    materialOptions: ["wood", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1594620302200-9a762244a156?w=400",
    description: "Display books and decor"
  },
  {
    name: "TV Stand",
    type: "Storage",
    defaultDimensions: { width: 1.5, height: 0.5, depth: 0.4 },
    materialOptions: ["wood", "glass", "metal"],
    imageUrl: "https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=400",
    description: "Modern entertainment center"
  },
  {
    name: "Dresser",
    type: "Storage",
    defaultDimensions: { width: 1.2, height: 0.9, depth: 0.5 },
    materialOptions: ["wood", "laminate"],
    imageUrl: "https://images.unsplash.com/photo-1595515106969-1ce29566ff1c?w=400",
    description: "Classic bedroom storage"
  },

  // LIGHTING
  {
    name: "Floor Lamp",
    type: "Lighting",
    defaultDimensions: { width: 0.3, height: 1.7, depth: 0.3 },
    materialOptions: ["metal", "wood", "brass"],
    imageUrl: "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400",
    description: "Adjustable reading light"
  },
  {
    name: "Table Lamp",
    type: "Lighting",
    defaultDimensions: { width: 0.25, height: 0.5, depth: 0.25 },
    materialOptions: ["ceramic", "metal", "glass"],
    imageUrl: "https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400",
    description: "Decorative bedside lighting"
  },
  {
    name: "Pendant Light",
    type: "Lighting",
    defaultDimensions: { width: 0.4, height: 0.5, depth: 0.4 },
    materialOptions: ["metal", "glass", "wood"],
    imageUrl: "https://images.unsplash.com/photo-1524484485831-a92ffc0de03f?w=400",
    description: "Hanging ceiling fixture"
  },
  {
    name: "Arc Floor Lamp",
    type: "Lighting",
    defaultDimensions: { width: 0.4, height: 2.0, depth: 0.4 },
    materialOptions: ["metal", "brass"],
    imageUrl: "https://images.unsplash.com/photo-1550253617-c2ecc06e2e6d?w=400",
    description: "Dramatic curved design"
  }
];

const seedDatabase = async () => {
  try {
    console.log("🔌 Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ Connected to MongoDB\n");

    // Clear existing data
    console.log("🗑️  Clearing existing catalog...");
    await Catalog.deleteMany({});
    console.log("✅ Catalog cleared\n");

    // Insert realistic furniture
    console.log("📦 Inserting realistic furniture catalog...");
    const insertedItems = await Catalog.insertMany(realisticFurniture);
    console.log(`✅ Inserted ${insertedItems.length} furniture items\n`);

    // Show summary by category
    const categories = ["Sofa", "Chair", "Table", "Bed", "Storage", "Lighting"];
    console.log("📊 Catalog Summary:");
    for (const category of categories) {
      const count = insertedItems.filter(item => item.type === category).length;
      console.log(`   ${category}: ${count} items`);
    }

    // Create a sample layout
    console.log("\n🏠 Creating sample layout...");
    await Layout.deleteMany({});
    
    const sampleLayout = {
      userId: "demo_user",
      name: "Modern Living Room",
      furnitureItems: [
        {
          furnitureId: insertedItems.find(i => i.name === "Modern L-Shaped Sectional")?._id.toString(),
          position: { x: -0.5, y: 0.425, z: -1.5 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "gray", material: "fabric" }
        },
        {
          furnitureId: insertedItems.find(i => i.name === "Round Coffee Table")?._id.toString(),
          position: { x: 0, y: 0.225, z: 0 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "brown", material: "wood" }
        },
        {
          furnitureId: insertedItems.find(i => i.name === "Arc Floor Lamp")?._id.toString(),
          position: { x: 1.5, y: 1.0, z: -1.0 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "black", material: "metal" }
        }
      ]
    };

    const createdLayout = await Layout.create(sampleLayout);
    console.log(`✅ Created sample layout: "${createdLayout.name}"`);

    // Test JSON transformation
    console.log("\n🔍 Testing JSON transformation...");
    const testItem = insertedItems[0].toJSON();
    console.log(`Sample item _id type: ${typeof testItem._id}`);
    console.log(`Sample item _id value: ${testItem._id}`);
    console.log(`✅ All _ids are strings!\n`);

    console.log("✨ Database seeding complete!");
    console.log(`\n📝 Total items: ${insertedItems.length}`);
    console.log(`🏠 Sample layouts: 1\n`);

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error("❌ Seeding error:", error);
    await mongoose.connection.close();
    process.exit(1);
  }
};

seedDatabase();