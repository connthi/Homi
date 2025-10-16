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

## Getting Started
**Living Document**

Access our collaborative project planning and requirements document here:
**https://docs.google.com/document/d/1E2BtWbL34D-I5gje0G1xclRfbXhPhTDIb9RfgBJMiEo/edit?usp=sharing**
## Clone the Repository
```bash
git clone https://github.com/uwproject-homi/homi.git
cd homi
