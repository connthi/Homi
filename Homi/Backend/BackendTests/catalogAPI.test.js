import request from "supertest";
import mongoose from "mongoose";
import app from "../server.js";
import Catalog from "../models/catalogModel.js";
import dotenv from "dotenv";

// Load environment variables (like MONGO_URI) before tests run
dotenv.config();

// Default MongoDB URI for testing (fallback if .env file doesn't exist)
const MONGO_URI = process.env.MONGO_URI || "mongodb+srv://Homi_db_user:Z3ruSgh5GxvBU5bz@homi.0xgveje.mongodb.net/?retryWrites=true&w=majority&appName=Homi";

// Before any tests run, connect to MongoDB using the URI from our .env file
beforeAll(async () => {
  await mongoose.connect(MONGO_URI);
});

// Clean up test data before each test
beforeEach(async () => {
  await Catalog.deleteMany({ name: /^Test/ });
});

// After all tests finish, close the MongoDB connection to prevent hanging processes
afterAll(async () => {
  await Catalog.deleteMany({ name: /^Test/ });
  await mongoose.connection.close();
});

// The main test suite for the Catalog API
describe("Catalog API", () => {

  // Test #1: Check if the catalog returns an array (may be empty or have existing data)
  it("should return an array of catalog items", async () => {
    const res = await request(app).get("/api/catalog");

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // Test #2: Check if we can successfully create a new catalog item
  it("should create a new catalog item", async () => {
    const item = {
      name: "Test Chair",
      type: "Chair",
      defaultDimensions: { width: 0.5, height: 0.9, depth: 0.5 },
      materialOptions: ["Wood", "Metal"]
    };

    const res = await request(app).post("/api/catalog").send(item);

    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe("Test Chair");
    expect(res.body.type).toBe("Chair");
    expect(res.body.defaultDimensions.width).toBe(0.5);
    expect(res.body.defaultDimensions.height).toBe(0.9);
    expect(res.body.defaultDimensions.depth).toBe(0.5);
    expect(Array.isArray(res.body.materialOptions)).toBe(true);
    expect(res.body.materialOptions).toContain("Wood");
    expect(res.body.materialOptions).toContain("Metal");
    expect(typeof res.body._id).toBe("string");
  });

  // Test #3: Verify created item appears in GET request
  it("should return created catalog item in GET request", async () => {
    const item = {
      name: "Test Sofa",
      type: "Sofa",
      defaultDimensions: { width: 2.0, height: 0.8, depth: 0.9 },
      materialOptions: ["Leather", "Fabric"]
    };

    const createRes = await request(app).post("/api/catalog").send(item);
    expect(createRes.statusCode).toBe(201);
    const createdId = createRes.body._id;

    const getRes = await request(app).get("/api/catalog");
    expect(getRes.statusCode).toBe(200);
    
    const foundItem = getRes.body.find(cat => cat._id === createdId);
    expect(foundItem).toBeDefined();
    expect(foundItem.name).toBe("Test Sofa");
    expect(foundItem.type).toBe("Sofa");
  });

  // Test #4: Should reject catalog item with missing required fields
  it("should reject catalog item with missing name", async () => {
    const item = {
      type: "Table",
      defaultDimensions: { width: 1.0, height: 0.4, depth: 0.6 }
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(400);
  });

  // Test #5: Should reject catalog item with missing type
  it("should reject catalog item with missing type", async () => {
    const item = {
      name: "Test Table",
      defaultDimensions: { width: 1.0, height: 0.4, depth: 0.6 }
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(400);
  });

  // Test #6: Should reject catalog item with missing dimensions
  it("should reject catalog item with missing defaultDimensions", async () => {
    const item = {
      name: "Test Table",
      type: "Table"
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(400);
  });

  // Test #7: Should accept catalog item with optional fields
  it("should accept catalog item with optional fields", async () => {
    const item = {
      name: "Test Bed",
      type: "Bed",
      defaultDimensions: { width: 2.0, height: 0.5, depth: 2.0 },
      materialOptions: ["Wood"],
      imageUrl: "https://example.com/bed.jpg",
      description: "A comfortable test bed",
      modelFileName: "bed.usdz"
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe("Test Bed");
    expect(res.body.imageUrl).toBe("https://example.com/bed.jpg");
    expect(res.body.description).toBe("A comfortable test bed");
    expect(res.body.modelFileName).toBe("bed.usdz");
  });

  // Test #8: Should handle empty materialOptions array
  it("should accept catalog item with empty materialOptions", async () => {
    const item = {
      name: "Test Lamp",
      type: "Lighting",
      defaultDimensions: { width: 0.3, height: 0.5, depth: 0.3 },
      materialOptions: []
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(201);
    expect(Array.isArray(res.body.materialOptions)).toBe(true);
    expect(res.body.materialOptions.length).toBe(0);
  });

  // Test #9: Should return _id as string (for Swift compatibility)
  it("should return _id as string in response", async () => {
    const item = {
      name: "Test Cabinet",
      type: "Storage",
      defaultDimensions: { width: 1.0, height: 2.0, depth: 0.5 },
      materialOptions: ["Wood"]
    };

    const res = await request(app).post("/api/catalog").send(item);
    expect(res.statusCode).toBe(201);
    expect(typeof res.body._id).toBe("string");
    expect(res.body._id).toMatch(/^[a-f0-9]{24}$/);
  });
});
