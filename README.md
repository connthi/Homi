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

Homi is a room planning companion app that lets users create, manipulate, and save 3D furniture layouts. Whether you're moving into a new space or experimenting with different configurations, Homi helps you visualize your ideas instantly.

With Homi, users can:

  - 🛋 Add 3D furniture to a virtual room
  - ✋ Drag, rotate, and scale items using natural gestures
  - 🧭 Use dynamic camera controls to move around the space
  - 💾 Save layouts to their account
  - ☁️ Load past room designs from the cloud
  - 🎨 Customize wall colors when creating a new room
  - 🔐 Register, log in, and manage accounts (JWT auth)

Homi’s goal is to make 3D room design simple, fast, and accessible—all from your phone. 

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
  - `/api/auth` – User authentication (register, login, logout, refresh tokens, password reset)
  - `/api/layouts` – Create, read, update, delete room layouts  
  - `/api/catalog` – Retrieve furniture catalog data  
  - `/api/share` – Create and manage shareable layout links
- Interfaces with MongoDB for persistent storage  

## How to Report a Bug
We appreciate all bug reports!
To help us diagnose issues efficiently, please include:

Bug Report Template

Bug Description:
Short summary of the issue.
Steps to Reproduce:
- Step 1
- Step 2
- Step 3

Expected Behavior:
What you thought would happen.

Actual Behavior:
What happened instead.

Device Information:
- Device model
- iOS version
- App version

Screenshots:
If available.

Reporting Options
- GitHub Issues
- Email: ptang6@uw.edu
- In-app support (coming soon)

## Support & Community

Documentation: See DEVELOPER_GUIDE.md and USER_GUIDE.md

GitHub Issues: Report bugs and track progress

Contact: ptang6@uw.edu

## Getting Started
**Living Document**

Access our collaborative project planning and requirements document here:
**https://docs.google.com/document/d/1E2BtWbL34D-I5gje0G1xclRfbXhPhTDIb9RfgBJMiEo/edit?usp=sharing**
