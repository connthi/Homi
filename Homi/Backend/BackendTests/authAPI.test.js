import request from "supertest";
import mongoose from "mongoose";
import { jest } from "@jest/globals";
import dotenv from "dotenv";
import app from "../server.js";
import User from "../models/userModel.js";

dotenv.config();

// Default MongoDB URI for testing (fallback if .env file doesn't exist)
const MONGO_URI = process.env.MONGO_URI || "mongodb+srv://Homi_db_user:Z3ruSgh5GxvBU5bz@homi.0xgveje.mongodb.net/?retryWrites=true&w=majority&appName=Homi";

// Allow slower startup/teardown
jest.setTimeout(40000);

describe("Auth API", () => {
  beforeAll(async () => {
    await mongoose.connect(MONGO_URI);
  }, 40000);

  afterAll(async () => {
    // Cleanly tear everything down so Jest doesn't complain
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
  }, 40000);

  beforeEach(async () => {
    await User.deleteMany({});
  });

  it("registers a new user and returns auth tokens", async () => {
    const res = await request(app)
      .post("/api/auth/register")
      .send({
        email: "newuser@example.com",
        password: "Password123!",
        firstName: "New",
        lastName: "User"
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user.email).toBe("newuser@example.com");

    const userInDb = await User.findOne({ email: "newuser@example.com" });
    expect(userInDb).not.toBeNull();
    expect(userInDb.passwordHash).not.toBe("Password123!");
  });

  it("logs in an existing user", async () => {
    await request(app).post("/api/auth/register").send({
      email: "login@example.com",
      password: "Password123!"
    });

    const res = await request(app).post("/api/auth/login").send({
      email: "login@example.com",
      password: "Password123!"
    });

    expect(res.statusCode).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.user.email).toBe("login@example.com");
  });

  it("rejects invalid credentials", async () => {
    await request(app).post("/api/auth/register").send({
      email: "invalid@example.com",
      password: "Password123!"
    });

    const res = await request(app).post("/api/auth/login").send({
      email: "invalid@example.com",
      password: "WrongPassword!"
    });

    expect(res.statusCode).toBe(401);
  });

  it("refreshes tokens and revokes the previous refresh token", async () => {
    const registerRes = await request(app).post("/api/auth/register").send({
      email: "refresh@example.com",
      password: "Password123!"
    });

    const refreshToken = registerRes.body.refreshToken;

    // get new token pair
    const refreshRes = await request(app)
      .post("/api/auth/refresh")
      .send({ refreshToken });

    expect(refreshRes.statusCode).toBe(200);
    expect(refreshRes.body.accessToken).toBeDefined();
    expect(refreshRes.body.refreshToken).toBeDefined();

    // previous refresh token should no longer be valid
    const secondRefresh = await request(app)
      .post("/api/auth/refresh")
      .send({ refreshToken });

    expect(secondRefresh.statusCode).toBe(401);
  });

  it("returns the current user when provided a valid access token", async () => {
    const registerRes = await request(app).post("/api/auth/register").send({
      email: "me@example.com",
      password: "Password123!"
    });

    const accessToken = registerRes.body.accessToken;

    const res = await request(app)
      .get("/api/auth/me")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.user.email).toBe("me@example.com");
  });

  it("invalidates refresh tokens on logout", async () => {
    const registerRes = await request(app).post("/api/auth/register").send({
      email: "logout@example.com",
      password: "Password123!"
    });

    const refreshToken = registerRes.body.refreshToken;

    await request(app).post("/api/auth/logout").send({ refreshToken });

    const res = await request(app)
      .post("/api/auth/refresh")
      .send({ refreshToken });

    expect(res.statusCode).toBe(401);
  });
});
