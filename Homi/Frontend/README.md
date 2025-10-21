# Homi iOS Frontend

The native iOS frontend for Homi, built with SwiftUI and SceneKit for high-performance 3D room design and visualization.

## 🚀 Features

- **3D Room Visualization** - Real-time rendering using SceneKit
- **Interactive Furniture Manipulation** - Drag, drop, scale, and rotate furniture with touch gestures
- **Furniture Catalog** - Browse and select from a curated collection of furniture
- **Layout Management** - Save, load, and manage room layouts
- **Intuitive UI** - Clean SwiftUI interface following Apple's Human Interface Guidelines

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ (for development)

## 🛠 Setup Instructions

### 1. Prerequisites

Make sure you have the following installed:
- [Xcode](https://developer.apple.com/xcode/) (latest version)
- [Node.js](https://nodejs.org/) (for backend)
- [MongoDB](https://www.mongodb.com/) (for backend)

### 2. Backend Setup

First, ensure your backend is running:

```bash
cd ../Backend
npm install
npm start
```

The backend should be running on `http://localhost:5000`

### 3. iOS Project Setup

1. Navigate to the Frontend directory:
   ```bash
   cd Homi/Frontend
   ```

2. Run the setup script:
   ```bash
   ./setup_ios.sh
   ```

3. Open the project in Xcode:
   ```bash
   open Homi.xcodeproj
   ```

### 4. Build and Run

1. Select your target device or simulator in Xcode
2. Press `⌘+R` to build and run the project
3. The app will launch and connect to your backend

## 🏗 Project Structure

```
Homi/
├── HomiApp.swift              # Main app entry point
├── ContentView.swift          # Root view with tab navigation
├── RoomView.swift             # 3D room visualization with SceneKit
├── CatalogView.swift          # Furniture catalog browser
├── Models.swift               # Data models matching backend API
├── APIService.swift           # Backend API communication
├── LayoutManager.swift        # Layout and furniture management
├── Assets.xcassets/           # App icons and assets
└── Preview Content/           # SwiftUI preview assets
```

## 🎯 Key Components

### SceneKit Integration

The `RoomView` uses SceneKit to render a 3D room environment with:
- **Room Geometry** - Floor, walls, and basic room structure
- **Furniture Rendering** - 3D furniture models with materials
- **Camera Controls** - Automatic camera positioning and lighting
- **Gesture Recognition** - Touch gestures for furniture manipulation

### Data Models

Swift models that mirror the backend API:
- `Layout` - Complete room layout with furniture items
- `FurnitureItem` - Individual furniture with position, rotation, scale
- `CatalogItem` - Available furniture types and properties
- `FurnitureNode` - SceneKit node wrapper for 3D rendering

### API Service

RESTful communication with the backend:
- **Layout Management** - Create, read, update, delete layouts
- **Catalog Access** - Fetch available furniture items
- **Error Handling** - Comprehensive error management
- **Async/Await** - Modern Swift concurrency

## 🎮 User Interface

### Main Navigation

The app uses a tab-based navigation with three main sections:

1. **Room Tab** - 3D room visualization and editing
2. **Catalog Tab** - Furniture browsing and selection
3. **Layouts Tab** - Saved layout management

### 3D Room Interface

- **Room View** - Full-screen 3D scene with furniture
- **Edit Mode** - Toggle for furniture manipulation
- **Gesture Controls** - Tap to select, drag to move, pinch to scale, rotate to turn
- **Save/Load** - Persistent layout management

### Catalog Interface

- **Search & Filter** - Find furniture by name or category
- **Category Tabs** - Filter by furniture type (Sofa, Chair, Table, etc.)
- **Item Cards** - Detailed furniture information with dimensions
- **Add to Room** - Direct integration with room editor

## 🔧 Development

### Adding New Furniture Types

1. Update the backend catalog with new items
2. The iOS app will automatically fetch and display them
3. Add custom 3D models by extending `FurnitureNode.setupGeometry()`

### Customizing Room Layout

Modify `RoomConfiguration` in `Models.swift` to change:
- Room dimensions
- Wall thickness
- Default materials
- Lighting setup

### Extending Gestures

Add new gesture recognizers in `SceneKitView.Coordinator`:
- Implement gesture handler methods
- Update furniture properties
- Call appropriate `LayoutManager` methods

## 🐛 Troubleshooting

### Common Issues

1. **Backend Connection Failed**
   - Ensure backend is running on `localhost:5000`
   - Check network connectivity
   - Verify CORS settings in backend

2. **3D Scene Not Loading**
   - Check SceneKit framework import
   - Verify device supports Metal rendering
   - Test on physical device if simulator fails

3. **Furniture Not Appearing**
   - Check catalog API response
   - Verify furniture node creation
   - Debug SceneKit node hierarchy

### Debug Mode

Enable debug logging by setting:
```swift
// In APIService.swift
private let debugMode = true
```

## 📚 API Reference

### Backend Endpoints

- `GET /api/layouts` - Fetch all layouts
- `POST /api/layouts` - Create new layout
- `GET /api/catalog` - Fetch furniture catalog
- `PUT /api/layouts/:id` - Update layout
- `DELETE /api/layouts/:id` - Delete layout

### Data Models

See `Models.swift` for complete Swift model definitions matching the backend schema.

## 🚀 Next Steps

### Planned Features

- **ARKit Integration** - Augmented reality room visualization
- **Real-time Collaboration** - Multi-user editing with WebSocket
- **Advanced Materials** - PBR materials and textures
- **Export Functionality** - Share layouts as images or 3D files
- **Custom Furniture** - User-uploaded 3D models

### Performance Optimization

- **LOD System** - Level-of-detail for complex scenes
- **Occlusion Culling** - Hide non-visible furniture
- **Texture Streaming** - Efficient material loading
- **Memory Management** - Optimize SceneKit node lifecycle

## 🤝 Contributing

1. Follow Swift style guidelines
2. Add unit tests for new features
3. Update documentation for API changes
4. Test on multiple device sizes
5. Ensure accessibility compliance

## 📄 License

This project is part of the Homi application suite. See the main project README for licensing information.
