# Homi: Your Space, Your Way

**Homi** is a high-performance **native iOS mobile application** designed to simplify interior room design and visualization. Built using **Swift** and **SceneKit**, Homi provides an intuitive 3D environment where users can easily **drag, drop, scale, and rotate furniture** to plan their living spaces — no 3D modeling experience required.

---

## Team Members
- **Connor Thibault** – Project Manager  
- **Phong Tang** – Full Stack Engineer (Frontend/UI)  
- **Zubair Sabry** – Full Stack Engineer (3D Rendering & Interaction)  
- **Ebrahim Elmi** – Full Stack Engineer / DevOps  
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
- Interfaces with MongoDB for persistent storage  
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
## Clone the Repository
```bash
git clone https://github.com/uwproject-homi/homi.git
cd homi

## 🧱 Build Instructions

Backend (Node.js + Express)
1. The production backend is **hosted on Render**, already configured with a live MongoDB database.
   - No `.env` setup is required to run the system using the deployed backend.
2. To run locally (optional):
   ```bash
   cd Homi/Backend
   npm install
   npm start

## If you wish to test locally, create a .env file in Homi/Backend with:
MONGO_URI=<your own MongoDB Atlas URI>
PORT=5001

## iOS Frontend (Swift + SceneKit)
Open the iOS project in Xcode:
  - Open Homi/Homi/Frontend/Homi
  - Delete the given folder leaving only the root directory
  - Move all files in Homi/Homi/Frontend/Homi into the root xcode directory
  - Ensure the deployment target is iOS 17.0 or later.
  - Press Run ▶️ in Xcode to build and launch the app on an iPhone simulator or connected device.

## 🧪 Test Instructions
## Backend Tests
1. Automated backend tests validate API endpoints, database connections, and catalog data consistency.
From the backend directory:
  - cd Homi/Backend
  - npm test
This runs all tests located in:
  - catalogAPI.test.js
  - layoutAPI.test.js
  - database.test.js
The CI/CD pipeline (.github/workflows/ci.yml) automatically runs:
  - Code quality checks (ESLint, formatting placeholders)
  - Security scans (npm audit, Snyk)
  - Integration test placeholders for future builds
Test results are printed to the console and verified automatically in GitHub Actions.

## 🚀 Run Instructions
## Running the Full System
1. Ensure the backend is running (either locally or via Render deployment).
2. Launch the iOS app in Xcode using Run ▶️.
3. In the app:
      - Tap Start new design
      - Tap Add Furniture → Select a furniture item (e.g., Sofa).
      - The selected model appears in the 3D room.
      - Select the model to move, rotate, or scale the model
      - Save the layout to store it in the cloud database.

This demonstrates the fully functional end-to-end prototype, where:
  - The frontend (iOS app) sends API requests.
  - The backend (Express server on Render) handles CRUD operations.
  - The database (MongoDB Atlas) persists user data and furniture metadata.
