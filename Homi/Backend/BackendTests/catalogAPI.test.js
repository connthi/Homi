import request from "supertest";
import mongoose from "mongoose";
import app from "../server.js";
import dotenv from "dotenv";

// Load environment variables (like MONGO_URI) before tests run
dotenv.config();

// Before any tests run, connect to MongoDB using the URI from our .env file
beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI);
});

// After all tests finish, close the MongoDB connection to prevent hanging processes
afterAll(async () => {
  await mongoose.connection.close();
});

// The main test suite for the Catalog API
describe("Catalog API", () => {

  // Test #1: Check if the catalog initially returns an empty array
  it("should return an empty catalog initially", async () => {
    // Send a GET request to the /api/catalog endpoint
    const res = await request(app).get("/api/catalog");

    // Expect HTTP status 200 (OK)
    expect(res.statusCode).toBe(200);

    // Expect the response body to be an array (even if it's empty)
    expect(Array.isArray(res.body)).toBe(true);
  });

  // Test #2: Check if we can successfully create a new catalog item
  it("should create a new catalog item", async () => {
    // Define a sample furniture item (like what the frontend would send)
    const item = {
      name: "Chair",
      type: "Furniture",
      defaultDimensions: { width: 1, height: 1, depth: 1 },
      materialOptions: ["Wood", "Metal"]
    };

    // Send a POST request with the item data to /api/catalog
    const res = await request(app).post("/api/catalog").send(item);

    // Expect HTTP status 201 (Created)
    expect(res.statusCode).toBe(201);

    // Expect the returned item to have the same name we sent
    expect(res.body.name).toBe("Chair");
  });
});
