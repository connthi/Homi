# Homi: Your Space, Your Way

**Homi** is a high-performance **native iOS mobile application** designed to simplify interior room design and visualization. Built using **Swift** and **SceneKit**, Homi provides an intuitive 3D environment where users can easily **drag, drop, scale, and rotate furniture** to plan their living spaces — no 3D modeling experience required.

---

## Team Members
- **Connor Thibault** – Project Manager  
- **Phong Tang** – Full Stack Engineer (3D Rendering & Interaction)  
- **Zubair Sabry** – Full Stack Engineer (Frontend/UI)  
- **Ebrahim Elmi** – Full Stack Engineer (DevOps)
- **Hussein Abdi** – Full Stack Engineer (Backend & Database)

---

## Project Overview

Homi was created to make **room planning effortless** by offering users a native 3D tool to design and experiment with room layouts before physically rearranging anything.

Users can:
- Create a 3D digital version of their room  
- Add and manipulate furniture interactively  
- Adjust camera angles and perspectives in real time  
- Save and load custom room layouts  
- Export their designs as images or share them with others  

---

## Key Features (MVP)

- **3D Room Visualization** – Real-time rendering using SceneKit with smooth interaction performance.  
- **Drag & Drop Interface** – Touch gestures for intuitive furniture manipulation (drag, rotate, scale).  
- **Dynamic Camera Controls** – Pan, zoom, and orbit around the room seamlessly.  
- **Save & Load Layouts** – Persist room designs via cloud-based backend (MongoDB).  
- **Export Layouts as Images** – Capture 3D scenes to share or save locally.  

### Stretch Goals (Post-MVP)
- **Augmented Reality (ARKit) Integration** – Visualize layouts in your real-world environment.  
- **Real-Time Collaboration** – Multi-user editing with WebSocket synchronization.  

---

## Technology Stack

| Layer | Technology | Description |
|-------|-------------|-------------|
| **Frontend (iOS)** | **Swift + SwiftUI + SceneKit** | Native iOS application handling UI, gestures, and 3D rendering |
| **Backend** | **Node.js + Express** | RESTful API for layouts and furniture catalog |
| **Database** | **MongoDB (Atlas)** | Stores user layouts, catalog items, and metadata |
| **Cloud Storage (Stretch)** | AWS S3 | Hosts 3D assets and images |
| **Version Control** | GitHub | Source control, pull requests, issue tracking |
| **Communication** | Discord / Ed | Daily collaboration and sprint coordination |

---

## System Architecture

Homi follows a **client-server model** optimized for modularity and performance.

**Frontend (iOS App):**
- Built using Swift and SceneKit  
- Handles user interaction, gesture recognition, and 3D object rendering  
- Uses Apple’s Human Interface Guidelines for an intuitive user experience  

**Backend (Node.js + Express):**
- Provides RESTful endpoints for:
  - `/layouts` – Create, read, update, delete room layouts  
  - `/catalog` – Retrieve furniture catalog data  
  - `/auth` – User registration, login, logout, refresh, and profile lookups  
- Interfaces with MongoDB for persistent storage  
  
### Authentication API & Environment Variables

The backend now exposes `/api/auth` with the following core endpoints:
- `POST /auth/register` – Create a new user and receive access/refresh tokens.
- `POST /auth/login` – Exchange credentials for a fresh token pair.
- `POST /auth/refresh` – Rotate refresh tokens and obtain a new access token.
- `POST /auth/logout` – Revoke the supplied refresh token.
- `GET /auth/me` – Return the authenticated user's profile (requires `Authorization: Bearer <token>`).

Set these environment variables for secure deployments (defaults exist for local dev but **must** be overridden in production):
- `ACCESS_TOKEN_SECRET` – HMAC secret for signing short-lived access tokens.
- `REFRESH_TOKEN_SECRET` – HMAC secret for refresh tokens (should differ from the access secret).
- Optional hardening knobs: `ACCESS_TOKEN_TTL`, `REFRESH_TOKEN_TTL`, `AUTH_PBKDF2_ITERATIONS`, `AUTH_PBKDF2_KEY_LENGTH`, `AUTH_PBKDF2_DIGEST`, `MAX_REFRESH_TOKENS`.
---

## Operational Use Case (Prototype)

As of Week 4, the following end-to-end use case is fully functional:

### Use Case 1: Place and Manipulate a Furniture Item

**User Action:** User taps the **"Add Furniture"** button.  
**System Response:** The system displays the **Furniture Catalog** list fetched from the backend.

**User Action:** User selects a **"Sofa"** item from the catalog.  
**System Response:** The system instantiates a **3D model** of the sofa at the center of the room layout.

**User Action:** User taps on the sofa and choose to move, rotate, or scale the sofa.  
**System Response:** The system highlights the funiture, and provides a UI that says
move, rotate, scale

**User Action:** User taps on move and drag the sofa around the room.
**System Response:** The system moves the sofa object around its **horizontal axis**.

**User Action:** User taps on scale and performs a **two-finger enlarge gesture** on the sofa.  
**System Response:** The system scales the sofa object on the size depending on the action.

**User Action:** User taps on rotate and performs a **two-finger rotation gesture** on the sofa.  
**System Response:** The system rotates the sofa object around its **vertical axis**.

**User Action:** User taps done.  
**System Response:** The system **deselects** the sofa, registering its final **position and rotation**.

This use case demonstrates the complete integration of all major system components:
- **Frontend (iOS/SceneKit):** Gesture handling, 3D object rendering, and camera controls  
- **Backend (Node.js/Express):** Serves the furniture catalog via API requests  
- **Database (MongoDB Atlas):** Stores catalog data used for spawning 3D models

---

## Getting Started
**Living Document**

Access our collaborative project planning and requirements document here:
**https://docs.google.com/document/d/1E2BtWbL34D-I5gje0G1xclRfbXhPhTDIb9RfgBJMiEo/edit?usp=sharing**
