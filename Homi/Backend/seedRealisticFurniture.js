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

    // CHAIRS
    const gamingChair = {
      name: "Gaming Chair",  
      type: "Chair",        
      defaultDimensions: {
        width: 0.7,
        height: 1.3,
        depth: 0.7
      },
      materialOptions: ["leather"],
      imageUrl: "",
      description: "Ergonomic gaming chair with lumbar support and adjustable armrests",
      modelFileName: "Gameready_Gaming_Chair"
    };

    const modernChair = {
      name: "Modern Chair",
      type: "Chair",
      defaultDimensions: {
        width: 0.55,
        height: 0.85,
        depth: 0.6
      },
      materialOptions: ["fabric", "wood"],
      imageUrl: "",
      description: "Contemporary dining chair with clean lines",
      modelFileName: "Modern_chair"
    };

    // SPEAKERS & ELECTRONICS
    const speaker = {
      name: "Desktop Speaker",  
      type: "Speaker",      
      defaultDimensions: {
        width: 0.15,
        height: 0.25,
        depth: 0.2
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Compact wooden desktop speaker with quality sound",
      modelFileName: "Desktop_speaker_with_a_wooden_enclosure"
    };

    // BEDS
    const bed = {
      name: "Simple Bed",
      type: "Bed",
      defaultDimensions: {
        width: 1.6,
        height: 0.5,
        depth: 2.0
      },
      materialOptions: ["wood", "fabric"],
      imageUrl: "",
      description: "Comfortable bed",
      modelFileName: "Bed"
    };

    const childrenBed = {
      name: "Children's Bunk Bed",
      type: "Bed",
      defaultDimensions: {
        width: 1.0,
        height: 1.6,
        depth: 2.0
      },
      materialOptions: ["wood", "fabric"],
      imageUrl: "",
      description: "Space-saving bunk beds perfect for kids' rooms",
      modelFileName: "Children_bed"
    };

    // STORAGE
    const bookshelf = {
      name: "Bookshelf",
      type: "Bookshelf",
      defaultDimensions: {
        width: 0.8,
        height: 1.8,
        depth: 0.35
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Tall wooden bookshelf with multiple adjustable shelves",
      modelFileName: "Bookshelf"
    };

    const modernCabinet = {
      name: "Modern Cabinet",
      type: "Cabinet",
      defaultDimensions: {
        width: 1.2,
        height: 0.85,
        depth: 0.45
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Sleek modern cabinet with clean lines and ample storage",
      modelFileName: "Modern_cabinet"
    };

    const modernShelf = {
      name: "Modern Shelf",
      type: "Bookshelf",
      defaultDimensions: {
        width: 1.0,
        height: 1.5,
        depth: 0.3
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Floating wall shelf with contemporary design",
      modelFileName: "Modern_shelf"
    };

    const tvCabinet = {
      name: "TV Cabinet",
      type: "Cabinet",
      defaultDimensions: {
        width: 1.8,
        height: 0.5,
        depth: 0.4
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Low-profile TV stand with media storage compartments",
      modelFileName: "TV_cabinet"
    };

    // SOFAS & COUCHES
    const couch = {
      name: "Cozy Elegance Sofa",
      type: "Couch",
      defaultDimensions: {
        width: 2.1,
        height: 0.85,
        depth: 0.95
      },
      materialOptions: ["fabric", "leather"],
      imageUrl: "",
      description: "Elegant 3-seater sofa with plush cushions and comfort",
      modelFileName: "Cozy_Elegance"
    };

    const threeSeatCouch = {
      name: "Three Seat Couch",
      type: "Couch",
      defaultDimensions: {
        width: 2.0,
        height: 0.8,
        depth: 0.9
      },
      materialOptions: ["fabric", "leather"],
      imageUrl: "",
      description: "Classic 3-seater couch with contemporary styling",
      modelFileName: "3_seat_couch"
    };

    const sillyCouch = {
      name: "Playful Couch",
      type: "Couch",
      defaultDimensions: {
        width: 1.6,
        height: 0.75,
        depth: 0.85
      },
      materialOptions: ["fabric"],
      imageUrl: "",
      description: "Fun and whimsical couch with unique design elements",
      modelFileName: "Silly_couch"
    };

    // DESKS & TABLES
    const officeDesk = {
      name: "Office Desk",
      type: "Desk",
      defaultDimensions: {
        width: 1.4,
        height: 0.75,
        depth: 0.7
      },
      materialOptions: ["wood", "metal"],
      imageUrl: "",
      description: "Professional wooden office desk with spacious work surface",
      modelFileName: "Office_desks_wooden"
    };

    const lShapedDesk = {
      name: "L-Shaped Desk",
      type: "Desk",
      defaultDimensions: {
        width: 1.5,
        height: 0.75,
        depth: 1.5
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Corner L-shaped desk maximizing workspace area",
      modelFileName: "L_shaped_desk"
    };

    const table = {
      name: "Dining Table",
      type: "Table",
      defaultDimensions: {
        width: 1.6,
        height: 0.75,
        depth: 0.9
      },
      materialOptions: ["wood", "glass"],
      imageUrl: "",
      description: "Versatile dining table for family meals and gatherings",
      modelFileName: "PorTable"
    };

    const roundTable = {
      name: "Round Table",
      type: "Table",
      defaultDimensions: {
        width: 1.2,
        height: 0.75,
        depth: 1.2
      },
      materialOptions: ["wood"],
      imageUrl: "",
      description: "Circular dining table perfect for intimate conversations",
      modelFileName: "Round_table"
    };

    // DECORATIVE
    const christmasTree = {
      name: "Christmas Tree",
      type: "Decor",
      defaultDimensions: {
        width: 1.0,
        height: 1.8,
        depth: 1.0
      },
      materialOptions: ["plastic", "artificial"],
      imageUrl: "",
      description: "Festive artificial Christmas tree with full branches",
      modelFileName: "Christmas_tree"
    };

    const fireplace = {
      name: "Fireplace",
      type: "Decor",
      defaultDimensions: {
        width: 1.5,
        height: 1.0,
        depth: 0.4
      },
      materialOptions: ["marble", "stone"],
      imageUrl: "",
      description: "Classic marble fireplace adding warmth and elegance",
      modelFileName: "Fireplace"
    };

    const items = [
      gamingChair, 
      modernChair,
      speaker,
      bed, 
      childrenBed,
      bookshelf,
      modernCabinet,
      modernShelf,
      tvCabinet,
      couch, 
      threeSeatCouch,
      sillyCouch,
      officeDesk,
      lShapedDesk,
      table,
      roundTable,
      christmasTree,
      fireplace
    ];

    const inserted = await Catalog.insertMany(items);

    console.log(`✅ Added ${inserted.length} items to catalog\n`);
    console.log("📦 Catalog Items:");
    inserted.forEach(item => {
      console.log(`   • ${item.name} (${item.type}) - ${item.defaultDimensions.width}m × ${item.defaultDimensions.depth}m × ${item.defaultDimensions.height}m`);
    });

    await mongoose.connection.close();
    console.log("\n✅ Database connection closed");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    await mongoose.connection.close();
    process.exit(1);
  }
};

add3DModelToCatalog();