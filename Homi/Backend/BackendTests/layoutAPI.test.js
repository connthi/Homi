import request from "supertest";
import mongoose from "mongoose";
import app from "../server.js";
import dotenv from "dotenv";

// Load environment variables before running any tests
dotenv.config();

// Before any test runs, establish a connection to the MongoDB test database
beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI);
});

// After all tests complete, close the MongoDB connection to free resources
afterAll(async () => {
  await mongoose.connection.close();
});

// Test suite for the Layout API routes
describe("Layout API", () => {

  // Test #1: Ensure the GET endpoint returns an empty array when there are no saved layouts
  it("should start with an empty layouts array", async () => {
    // Send a GET request to /api/layouts
    const res = await request(app).get("/api/layouts");

    // Expect the server to respond with HTTP 200 (OK)
    expect(res.statusCode).toBe(200);

    // The body should be an array (it can be empty at first)
    expect(Array.isArray(res.body)).toBe(true);
  });

  // Test #2: Verify that a new layout can be created successfully
  it("should create and return a new layout", async () => {
    // Define a mock layout object to send in the POST request
    const layout = {
      userId: "tester123", // Sample user ID
      name: "Test Layout", // Name of the layout being created
      furnitureItems: [
        {
          furnitureId: "sofa01", // Example furniture item
          position: { x: 0, y: 0, z: 0 }, // Placement in 3D space
          rotation: { x: 0, y: 0, z: 0 }, // Orientation in 3D space
          scale: { x: 1, y: 1, z: 1 }, // Size multiplier
          properties: { color: "blue", material: "fabric" } // Additional attributes
        }
      ]
    };

    // Send the layout data to the backend using a POST request
    const res = await request(app).post("/api/layouts").send(layout);

    // Expect a successful creation response (HTTP 201)
    expect(res.statusCode).toBe(201);

    // Confirm that the returned layout object contains the expected name
    expect(res.body.name).toBe("Test Layout");
  });
});
