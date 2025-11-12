## DEVELOPER GUIDE

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

## File Structure

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
│   │   ├── models # Models for Homi
│   │   │   ├── catalogModel.js # Defines the Mongoose schema for catalog items, including furniture attributes and data transformations for JSON output.
│   │   │   └── layoutModel.js # Defines the Mongoose schema for room layouts, including furniture positions, rotations, and properties, with JSON transformations for frontend compatibility.
│   │   ├── routes # Backend routes for Homi
│   │   │   ├── catalogRoutes.js # Express router handling catalog API endpoints for retrieving and adding furniture items in the database.
│   │   │   └── layoutRoutes.js # Express router managing layout endpoints for creating, retrieving, updating, and deleting room layouts.
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
│   │       ├── CatalogView.swift # SwiftUI view displaying the furniture catalog with search, category filters, and responsive grid layout for browsing items.
│   │       ├── ContentView.swift # Main SwiftUI entry view managing app navigation. Hosts tabs for Home, Catalog, and Saved Layouts, and launches the 3D Room editor.
│   │       ├── HomiApp.swift # App entry point. Launches the main SwiftUI window and logs bundle contents to verify that 3D .usdz model files are properly included.
│   │       ├── LayoutManager.swift # Central state manager for layouts and furniture. Handles loading catalog data, creating, saving, and updating room layouts, and syncing 3D scene furniture nodes.
│   │       ├── Models.swift # Defines layout, furniture, and catalog data models, plus FurnitureNode for rendering and scaling 3D models in SceneKit.
│   │       ├── NewLayoutDialog.swift # Layout dialog for users when creating a new Layout
│   │       ├── RoomView.swift # Main 3D design interface. Lets users view, add, edit, move, rotate, and scale furniture in a virtual room using SceneKit with interactive SwiftUI controls.
│   │       └── tests # Frontend tests
│   └── LICENSE
└── README.md # Read me file for Homi
└── DEVELOPER_GUIDE.md # Developer guide for to run and test Homi
└── USER_GUIDE.md # User guide on how to use Homi
