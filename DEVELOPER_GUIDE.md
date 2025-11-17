## DEVELOPER GUIDE
This document provides complete setup, development, testing, and contribution instructions for developers working on the Homi Interior Design App.

## Prerequisites
Backend Requirements
  - Node.js 18+
  - npm 8+
  - MongoDB Atlas (production) OR local MongoDB (for development)
  - Git
iOS Frontend Requirements
  - macOS Ventura (13.0) or later
  - Xcode 15.0+
  - iOS Deployment Target: 17.0+
  - Swift 5.9+

## Clone the Repository

git clone https://github.com/uwproject-homi/homi.git
cd homi

## Build Instructions

Backend (Node.js + Express)
1. Need .env file. (Please email ptang6@uw.edu for the file information)
   - place the file in Backend folder.
3. To run locally:
   ```bash
   cd Homi/Backend
   npm install
   npm start

## iOS Frontend (Swift + SceneKit)
Open the iOS project in Xcode:
  - Open Homi/Homi/Frontend/Homi
  - Ensure the deployment target is iOS 17.0 or later.
  - Press Run in Xcode to build and launch the app on an iPhone simulator or connected device.

## Test Instructions
## Backend Tests
1. Automated backend tests validate API endpoints, database connections, and catalog data consistency.
From the backend directory:
  - cd Homi/Backend
  - npm install
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

## Adding new tests
(Backend) Create file in:
```
Homi/Backend/BackendTests/
```
Example:
```
const request = require("supertest");
const app = require("../server");

describe("MyFeature API", () => {
  it("returns 200", async () => {
    const res = await request(app).get("/api/my-feature");
    expect(res.status).toBe(200);
  });
});
```

(Frontend) Create file in:
```
Homi/Frontend/Homi/tests/
```
Example:
```
import XCTest
@testable import Homi

final class NewFeatureTests: XCTestCase {

    func testLogic() {
        let result = 1 + 1
        XCTAssertEqual(result, 2)
    }
}
```

## Run Instructions
## Running the Full System
1. Ensure the backend is running.
2. Launch the iOS app in Xcode using Run.
3. In the app:
      - Tap Start new design
      - Tap Add Furniture → Select a furniture item (e.g., Sofa).
      - The selected model appears in the 3D room.
      - Select the model to move, rotate, or scale the model
      - Save the layout to store it in the cloud database.


## Architecture Overview
Backend Architecture (Node.js + Express + MongoDB)
  - Routers: catalogRoutes, layoutRoutes, authRoutes
  - Models: catalogModel, layoutModel, userModel
  - Middleware: authMiddleware (JWT validation)
  - Database: MongoDB Atlas for production; MongoDB container/local for testing
  - Patterns
    - MVC
    - Service Layer
    - JWT Authentication
    - REST API Structure
iOS Architecture (SwiftUI + SceneKit)
  - LayoutManager: central app state manager
  - APIService: connects iOS → backend
  - SceneKit Coordinator manages gesture/movement/3D logic
  - SwiftUI screens for authentication, catalog, layout editing, and room view
  - Patterns
    - MVVM
    - SwiftUI State (@State, @EnvironmentObject, @Binding)
    - Unidirectional data flow
    - 3D SceneKit coordinators

## File Structure

```
.
├── ci-yml.md # GitHub Actions workflow for CI/CD automation.
├── docs
│   └── CI-CD.md # Documents the project’s GitHub Actions CI/CD pipeline, explaining jobs, triggers, environments, and testing steps.
├── Homi
│   ├── Backend # Backend for Homi
│   │   ├── BackendTests  # Backend tests for Homi
│   │   │   ├── catalogAPI.test.js # Tests the Catalog API endpoints. It checks that the catalog starts empty, allows creating new items, and that the backend correctly handles GET and POST requests.
│   │   │   ├── database.test.js # Verifies database model integrity. It ensures Catalog and Layout APIs return valid string _ids, proper date formats, and correctly structured JSON responses.
│   │   │   └── layoutAPI.test.js # Tests the Layout API endpoints, ensuring layouts can be fetched, created, and returned correctly with valid structure and responses.
│   │   ├── middleware  # middleware for Homi
│   │   │   └── authMiddelware.js # Middleware that verifies a JWT access token and attaches the authenticated user to the request. 
│   │   ├── models # Models for Homi
│   │   │   ├── catalogModel.js # Defines the Mongoose schema for catalog items, including furniture attributes and data transformations for JSON output.
│   │   │   └── layoutModel.js # Defines the Mongoose schema for room layouts, including furniture positions, rotations, and properties, with JSON transformations for frontend compatibility.
│   │   │   ├── userMode.js # Mongoose user model defining account fields, hashed passwords, refresh tokens, and safe JSON output.
│   │   ├── routes # Backend routes for Homi
│   │   │   ├── catalogRoutes.js # Express router handling catalog API endpoints for retrieving and adding furniture items in the database.
│   │   │   └── layoutRoutes.js # Express router managing layout endpoints for creating, retrieving, updating, and deleting room layouts.
│   │   │   ├── authRoutes.js # Authentication routes handling register, login, refresh tokens, logout, and fetching the current user.
│   │   ├── seedRealisticFurniture.js # Seeds the database with predefined 3D furniture items, clearing old catalog entries and inserting new ones for testing and demos.
│   │   └── server.js # Main backend entry point. Sets up Express, connects to MongoDB, and registers layout and catalog API routes.
│   ├── docs # Documents for Homi
│   │   ├── coding-guidelines # Coding guidelines
│   │   ├── reports # Weekly reports
│   │   │   ├── 20251020.md
│   │   │   ├── 20251027.md
│   │   │   └── 20251103.md
│   │   └── team-resources # Team resources for Homi
│   ├── Frontend # Frontend for Homi
│   │   └── Homi
│   │       ├── 3Dmodels # 3d models for Homi
│   │       ├── APIService.swift # Handles all backend communication for the iOS app, including fetching, saving, updating, and deleting layouts and catalog items via REST APIs.
│   │       ├── Authentication.swift # Main auth screen that toggles between login and register views.
│   │       ├── AuthManager.swift # Manages login, registration, token handling, and overall authentication state.
│   │       ├── AuthService.swift # Handles securely storing, retrieving, and clearing auth tokens using the iOS Keychain.
│   │       ├── CatalogView.swift # SwiftUI view displaying the furniture catalog with search, category filters, and responsive grid layout for browsing items.
│   │       ├── ContentView.swift # Main SwiftUI entry view managing app navigation. Hosts tabs for Home, Catalog, and Saved Layouts, and launches the 3D Room editor.
│   │       ├── HomiApp.swift # App entry point. Launches the main SwiftUI window and logs bundle contents to verify that 3D .usdz model files are properly included.
│   │       ├── LayoutManager.swift # Central state manager for layouts and furniture. Handles loading catalog data, creating, saving, and updating room layouts, and syncing 3D scene furniture nodes.
│   │       ├── LoginView.swift # Login screen UI allowing users to enter credentials and sign into their Homi account.
│   │       ├── Models.swift # Defines layout, furniture, and catalog data models, plus FurnitureNode for rendering and scaling 3D models in SceneKit.
│   │       ├── NewLayoutDialog.swift # Layout dialog for users when creating a new
│   │       ├── RegisterView.swift # Registration screen UI for creating a new Homi account with validation and error handling.
│   │       ├── RoomView.swift # Main 3D design interface. Lets users view, add, edit, move, rotate, and scale furniture in a virtual room using SceneKit with interactive SwiftUI controls.
│   │       └── tests # Frontend tests
│   └── LICENSE
└── README.md # Read me file for Homi
└── DEVELOPER_GUIDE.md # Developer guide for to run and test Homi
└── USER_GUIDE.md # User guide on how to use Homi
```