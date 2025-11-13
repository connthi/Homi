import request from "supertest";
import mongoose from "mongoose";
import app from "../server.js";
import Layout from "../models/layoutModel.js";
import dotenv from "dotenv";

// Load environment variables before running any tests
dotenv.config();

// Default MongoDB URI for testing (fallback if .env file doesn't exist)
const MONGO_URI = process.env.MONGO_URI || "mongodb+srv://Homi_db_user:Z3ruSgh5GxvBU5bz@homi.0xgveje.mongodb.net/?retryWrites=true&w=majority&appName=Homi";

// Before any test runs, establish a connection to the MongoDB test database
beforeAll(async () => {
  await mongoose.connect(MONGO_URI);
});

// Clean up test data before each test
beforeEach(async () => {
  await Layout.deleteMany({ name: /^Test/ });
});

// After all tests complete, close the MongoDB connection to free resources
afterAll(async () => {
  await Layout.deleteMany({ name: /^Test/ });
  await mongoose.connection.close();
});

// Test suite for the Layout API routes
describe("Layout API", () => {

  // Test #1: GET /api/layouts should return an array
  it("should return an array of layouts", async () => {
    const res = await request(app).get("/api/layouts");

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // Test #2: POST /api/layouts should create a new layout
  it("should create and return a new layout", async () => {
    const layout = {
      userId: "test_user_123",
      name: "Test Layout",
      furnitureItems: [
        {
          furnitureId: "sofa01",
          position: { x: 0, y: 0, z: 0 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "blue", material: "fabric" }
        }
      ]
    };

    const res = await request(app).post("/api/layouts").send(layout);

    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe("Test Layout");
    expect(res.body.userId).toBe("test_user_123");
    expect(Array.isArray(res.body.furnitureItems)).toBe(true);
    expect(res.body.furnitureItems.length).toBe(1);
    expect(res.body.furnitureItems[0].furnitureId).toBe("sofa01");
    expect(typeof res.body._id).toBe("string");
    expect(res.body.createdAt).toBeDefined();
  });

  // Test #3: POST /api/layouts should create layout with empty furnitureItems
  it("should create layout with empty furnitureItems array", async () => {
    const layout = {
      userId: "test_user_456",
      name: "Test Empty Layout",
      furnitureItems: []
    };

    const res = await request(app).post("/api/layouts").send(layout);

    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe("Test Empty Layout");
    expect(Array.isArray(res.body.furnitureItems)).toBe(true);
    expect(res.body.furnitureItems.length).toBe(0);
  });

  // Test #4: GET /api/layouts/:id should return a specific layout
  it("should return a specific layout by ID", async () => {
    const layout = {
      userId: "test_user_789",
      name: "Test Layout for GET",
      furnitureItems: []
    };

    const createRes = await request(app).post("/api/layouts").send(layout);
    expect(createRes.statusCode).toBe(201);
    const layoutId = createRes.body._id;

    const getRes = await request(app).get(`/api/layouts/${layoutId}`);
    expect(getRes.statusCode).toBe(200);
    expect(getRes.body._id).toBe(layoutId);
    expect(getRes.body.name).toBe("Test Layout for GET");
  });

  // Test #5: GET /api/layouts/:id should return 404 for non-existent layout
  it("should return 404 for non-existent layout ID", async () => {
    const fakeId = "507f1f77bcf86cd799439011"; // Valid ObjectId format but doesn't exist
    const res = await request(app).get(`/api/layouts/${fakeId}`);

    expect(res.statusCode).toBe(404);
    expect(res.body.message).toBe("Layout not found");
  });

  // Test #6: GET /api/layouts/:id should return 500 for invalid ID format
  it("should handle invalid layout ID format", async () => {
    const invalidId = "invalid-id-format";
    const res = await request(app).get(`/api/layouts/${invalidId}`);

    expect(res.statusCode).toBe(500);
  });

  // Test #7: PUT /api/layouts/:id should update an existing layout
  it("should update an existing layout", async () => {
    const layout = {
      userId: "test_user_update",
      name: "Test Layout Original",
      furnitureItems: []
    };

    const createRes = await request(app).post("/api/layouts").send(layout);
    expect(createRes.statusCode).toBe(201);
    const layoutId = createRes.body._id;

    const updateData = {
      userId: "test_user_update",
      name: "Test Layout Updated",
      furnitureItems: [
        {
          furnitureId: "chair01",
          position: { x: 1, y: 0, z: 1 },
          rotation: { x: 0, y: 90, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "red", material: "wood" }
        }
      ]
    };

    const updateRes = await request(app).put(`/api/layouts/${layoutId}`).send(updateData);
    expect(updateRes.statusCode).toBe(200);
    expect(updateRes.body.name).toBe("Test Layout Updated");
    expect(updateRes.body.furnitureItems.length).toBe(1);
    expect(updateRes.body.furnitureItems[0].furnitureId).toBe("chair01");
  });

  // Test #8: DELETE /api/layouts/:id should delete a layout
  it("should delete a layout by ID", async () => {
    const layout = {
      userId: "test_user_delete",
      name: "Test Layout to Delete",
      furnitureItems: []
    };

    const createRes = await request(app).post("/api/layouts").send(layout);
    expect(createRes.statusCode).toBe(201);
    const layoutId = createRes.body._id;

    const deleteRes = await request(app).delete(`/api/layouts/${layoutId}`);
    expect(deleteRes.statusCode).toBe(200);
    expect(deleteRes.body.message).toBe("Layout deleted");

    // Verify it's actually deleted
    const getRes = await request(app).get(`/api/layouts/${layoutId}`);
    expect(getRes.statusCode).toBe(404);
  });

  // Test #9: Layout should include furnitureItems with proper structure
  it("should create layout with multiple furniture items", async () => {
    const layout = {
      userId: "test_user_multi",
      name: "Test Multi-Furniture Layout",
      furnitureItems: [
        {
          furnitureId: "sofa01",
          position: { x: 0, y: 0, z: 0 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          properties: { color: "blue", material: "fabric" }
        },
        {
          furnitureId: "table01",
          position: { x: 2, y: 0, z: 1 },
          rotation: { x: 0, y: 45, z: 0 },
          scale: { x: 1.2, y: 1, z: 1.2 },
          properties: { color: "brown", material: "wood" }
        }
      ]
    };

    const res = await request(app).post("/api/layouts").send(layout);
    expect(res.statusCode).toBe(201);
    expect(res.body.furnitureItems.length).toBe(2);
    expect(res.body.furnitureItems[0].furnitureId).toBe("sofa01");
    expect(res.body.furnitureItems[1].furnitureId).toBe("table01");
    expect(typeof res.body.furnitureItems[0]._id).toBe("string");
    expect(typeof res.body.furnitureItems[1]._id).toBe("string");
  });

  // Test #10: Layout furnitureItems should have proper position/rotation/scale
  it("should preserve furniture item position, rotation, and scale", async () => {
    const layout = {
      userId: "test_user_pos",
      name: "Test Position Layout",
      furnitureItems: [
        {
          furnitureId: "chair01",
          position: { x: 1.5, y: 0.5, z: 2.0 },
          rotation: { x: 0, y: 90, z: 0 },
          scale: { x: 1.2, y: 1.0, z: 1.1 },
          properties: { color: "green", material: "plastic" }
        }
      ]
    };

    const res = await request(app).post("/api/layouts").send(layout);
    expect(res.statusCode).toBe(201);
    const item = res.body.furnitureItems[0];
    expect(item.position.x).toBe(1.5);
    expect(item.position.y).toBe(0.5);
    expect(item.position.z).toBe(2.0);
    expect(item.rotation.y).toBe(90);
    expect(item.scale.x).toBe(1.2);
    expect(item.scale.z).toBe(1.1);
    expect(item.properties.color).toBe("green");
    expect(item.properties.material).toBe("plastic");
  });

  // Test #11: GET /api/layouts should return all created layouts
  it("should return all layouts including newly created ones", async () => {
    const layout1 = {
      userId: "test_user_all",
      name: "Test Layout 1",
      furnitureItems: []
    };
    const layout2 = {
      userId: "test_user_all",
      name: "Test Layout 2",
      furnitureItems: []
    };

    await request(app).post("/api/layouts").send(layout1);
    await request(app).post("/api/layouts").send(layout2);

    const res = await request(app).get("/api/layouts");
    expect(res.statusCode).toBe(200);
    
    const testLayouts = res.body.filter(l => l.name.startsWith("Test Layout"));
    expect(testLayouts.length).toBeGreaterThanOrEqual(2);
  });
});
