import mongoose from "mongoose";
import dotenv from "dotenv";
import Catalog from "./models/catalogModel.js";

dotenv.config();

const add3DModelToCatalog = async () => {
  try {
    console.log("📌 Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ Connected to MongoDB\n");

    console.log("🗑️  Clearing old catalog...");
    const deleteResult = await Catalog.deleteMany({});
    console.log(`✅ Deleted ${deleteResult.deletedCount} old items\n`);

    // Gaming Chair - filename matches bundle
    const gamingChair = {
      name: "Gaming Chair",  
      type: "Chair",        
      defaultDimensions: {
        width: 0.65,    
        height: 1.1,        
        depth: 0.65          
      },
      materialOptions: ["leather"],
      imageUrl: "",
      description: "Comfortable modern gaming chair",
      modelFileName: "Gameready_Gaming_Chair"
    };

    const speaker = {
      name: "Desktop Speaker",  
      type: "Speaker",      
      defaultDimensions: {
        width: 0.3, 
        height: 0.4,        
        depth: 0.25          
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Wooden desktop speaker",
      modelFileName: "Desktop_speaker_with_a_wooden_enclosure"
    };

    const bed = {
      name: "Bed",
      type: "Bed",
      defaultDimensions: { width: 2.0, height: 0.6, depth: 2.2 },
      materialOptions: ["wood", "fabric"],
      imageUrl: "",
      description: "Queen-sized bed with soft fabric upholstery and wooden frame",
      modelFileName: "Bed"
    };

    const bookshelf = {
      name: "Bookshelf",
      type: "Bookshelf",
      defaultDimensions: { width: 1.0, height: 2.0, depth: 0.4 },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Tall wooden bookshelf with multiple compartments",
      modelFileName: "Bookshelf"
    };

    const couch = {
      name: "Couch",
      type: "Couch",
      defaultDimensions: { width: 2.2, height: 0.8, depth: 1.0 },
      materialOptions: ["fabric", "leather"],
      imageUrl: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800",
      description: "Modern 3-seater couch with comfortable cushions",
      modelFileName: "Cozy_Elegance"
    };

    const officeDesk = {
      name: "Office Desk",
      type: "Desk",
      defaultDimensions: { width: 1.5, height: 0.75, depth: 0.7 },
      materialOptions: ["wood", "metal"],
      imageUrl: "",
      description: "Spacious wooden desk with sleek metal frame for productivity",
      modelFileName: "Office_desks_wooden"
    };

    const table = {
      name: "Dining Table",
      type: "Table",
      defaultDimensions: { width: 1.8, height: 0.75, depth: 1.0 },
      materialOptions: ["wood", "glass"],
      imageUrl: "",
      description: "Rectangular dining table suitable for 4–6 people",
      modelFileName: "PorTable"
    };

    const items = [gamingChair, speaker, bed, bookshelf, couch, officeDesk, table];
    const inserted = await Catalog.insertMany(items);

    console.log(`✅ Added ${inserted.length} items to catalog`);
    inserted.forEach(item => {
      console.log(`   • ${item.name} (${item.modelFileName}.usdz)`);
    });

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    await mongoose.connection.close();
    process.exit(1);
  }
};

add3DModelToCatalog();