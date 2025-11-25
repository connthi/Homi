import request from "supertest";
import mongoose from "mongoose";
import app from "../server.js";
import Catalog from "../models/catalogModel.js";
import Layout from "../models/layoutModel.js";
import User from "../models/userModel.js";
import dotenv from "dotenv";

dotenv.config();

// Default MongoDB URI for testing (fallback if .env file doesn't exist)
const MONGO_URI = process.env.MONGO_URI || "mongodb+srv://Homi_db_user:Z3ruSgh5GxvBU5bz@homi.0xgveje.mongodb.net/?retryWrites=true&w=majority&appName=Homi";

// Helper function to get auth token for tests
async function getAuthToken() {
  const testEmail = `test_${Date.now()}@example.com`;
  const registerRes = await request(app)
    .post("/api/auth/register")
    .send({
      email: testEmail,
      password: "Password123!",
      firstName: "Test",
      lastName: "User"
    });
  
  if (registerRes.statusCode === 201) {
    return registerRes.body.accessToken;
  }
  
  // If registration fails, try login
  const loginRes = await request(app)
    .post("/api/auth/login")
    .send({
      email: testEmail,
      password: "Password123!"
    });
  
  return loginRes.body.accessToken;
}

beforeAll(async () => {
  await mongoose.connect(MONGO_URI);
});

afterAll(async () => {
  await mongoose.connection.close();
});

describe("Database Models JSON Transformation", () => {
  beforeEach(async () => {
    // Clear test data before each test
    await Catalog.deleteMany({ name: /^Test/ });
    await Layout.deleteMany({ name: /^Test/ });
    await User.deleteMany({ email: /^test_/ });
  });

  afterAll(async () => {
    // Clean up test data
    await Catalog.deleteMany({ name: /^Test/ });
    await Layout.deleteMany({ name: /^Test/ });
    await User.deleteMany({ email: /^test_/ });
  });

  describe("Catalog Model", () => {
    it("should return _id as string via API", async () => {
      const token = await getAuthToken();
      const catalogData = {
        name: "Test API Sofa",
        type: "Sofa",
        defaultDimensions: { width: 2.0, height: 0.8, depth: 0.9 },
        materialOptions: ["leather", "fabric"]
      };

      const response = await request(app)
        .post("/api/catalog")
        .set("Authorization", `Bearer ${token}`)
        .send(catalogData)
        .expect(201);

      // Verify _id is a string
      expect(typeof response.body._id).toBe("string");
      expect(response.body._id).toMatch(/^[a-f0-9]{24}$/);
      expect(response.body.name).toBe("Test API Sofa");
    });

    it("should return all catalog items with string _ids", async () => {
      const token = await getAuthToken();
      // Create a test item first
      await request(app)
        .post("/api/catalog")
        .set("Authorization", `Bearer ${token}`)
        .send({
          name: "Test API Chair",
          type: "Chair",
          defaultDimensions: { width: 0.5, height: 0.9, depth: 0.5 },
          materialOptions: ["wood"]
        });

      const response = await request(app)
        .get("/api/catalog")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
      
      // Check that all items have string _ids
      response.body.forEach(item => {
        expect(typeof item._id).toBe("string");
        expect(item._id).toMatch(/^[a-f0-9]{24}$/);
      });
    });
  });

  describe("Layout Model", () => {
    it("should return layout with string _id and furniture item _ids via API", async () => {
      const token = await getAuthToken();
      // First create a catalog item
      const catalogResponse = await request(app)
        .post("/api/catalog")
        .set("Authorization", `Bearer ${token}`)
        .send({
          name: "Test API Table",
          type: "Table",
          defaultDimensions: { width: 1.2, height: 0.4, depth: 0.6 },
          materialOptions: ["wood"]
        });

      const catalogId = catalogResponse.body._id;

      // Create a layout with furniture
      const layoutData = {
        userId: "test_user",
        name: "Test API Room",
        furnitureItems: [
          {
            furnitureId: catalogId,
            position: { x: 0, y: 0, z: 0 },
            rotation: { x: 0, y: 0, z: 0 },
            scale: { x: 1, y: 1, z: 1 },
            properties: { color: "brown", material: "wood" }
          }
        ]
      };

      const response = await request(app)
        .post("/api/layouts")
        .set("Authorization", `Bearer ${token}`)
        .send(layoutData)
        .expect(201);

      // Verify layout _id is string
      expect(typeof response.body._id).toBe("string");
      expect(response.body._id).toMatch(/^[a-f0-9]{24}$/);

      // Verify furniture item _id is string
      expect(response.body.furnitureItems.length).toBe(1);
      expect(typeof response.body.furnitureItems[0]._id).toBe("string");
      expect(response.body.furnitureItems[0]._id).toMatch(/^[a-f0-9]{24}$/);
    });

    it("should return layouts with proper date format", async () => {
      const token = await getAuthToken();
      const layoutData = {
        userId: "test_user",
        name: "Test API Layout Date",
        furnitureItems: []
      };

      const response = await request(app)
        .post("/api/layouts")
        .set("Authorization", `Bearer ${token}`)
        .send(layoutData)
        .expect(201);

      // Verify createdAt exists and is a valid date string
      expect(response.body.createdAt).toBeDefined();
      const date = new Date(response.body.createdAt);
      expect(date.toString()).not.toBe("Invalid Date");
    });

    it("should retrieve layout with all fields as strings", async () => {
      const token = await getAuthToken();
      // Create a layout
      const createResponse = await request(app)
        .post("/api/layouts")
        .set("Authorization", `Bearer ${token}`)
        .send({
          userId: "test_user",
          name: "Test API Retrieve",
          furnitureItems: []
        });

      const layoutId = createResponse.body._id;

      // Retrieve it
      const response = await request(app)
        .get(`/api/layouts/${layoutId}`)
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(typeof response.body._id).toBe("string");
      expect(response.body._id).toMatch(/^[a-f0-9]{24}$/);
    });
  });
});