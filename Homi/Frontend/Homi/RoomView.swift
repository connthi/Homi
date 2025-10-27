import SwiftUI
import SceneKit

struct RoomView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @Environment(\.dismiss) var dismiss
    @State private var showingNewLayoutDialog = false
    @State private var showingSaveDialog = false
    @State private var showingCatalogSheet = false
    @State private var newLayoutName = ""
    @State private var selectedFurnitureNode: FurnitureNode?
    @State private var isEditing = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        ZStack {
            // 3D Scene View
            Interactive3DRoomView(
                furnitureNodes: layoutManager.furnitureNodes,
                selectedNode: $selectedFurnitureNode,
                isEditing: $isEditing,
                onFurnitureMoved: { furnitureItem, position in
                    layoutManager.updateFurniturePosition(furnitureItem, position: position)
                },
                onFurnitureRotated: { furnitureItem, rotation in
                    layoutManager.updateFurnitureRotation(furnitureItem, rotation: rotation)
                },
                onFurnitureScaled: { furnitureItem, scale in
                    layoutManager.updateFurnitureScale(furnitureItem, scale: scale)
                }
            )
            .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // Top Controls
                HStack {
                    Button(action: {
                        // Go back to main menu
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if let layout = layoutManager.currentLayout {
                        Text(layout.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if layoutManager.currentLayout != nil {
                        Button("Save") {
                            saveLayout()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                Spacer()
                
                // Camera Controls Hint
                if !isEditing && !showingCatalogSheet && selectedFurnitureNode == nil {
                    VStack(spacing: 4) {
                        Text("Camera Controls")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• Drag: Rotate camera")
                        Text("• Two fingers: Pan")
                        Text("• Pinch: Zoom")
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding()
                }
                
                // Furniture Selected Hint
                if !isEditing && selectedFurnitureNode != nil {
                    VStack(spacing: 4) {
                        Text("Furniture Selected")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Tap 'Edit' to move, scale, or rotate")
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(8)
                    .padding()
                }
                
                // Edit Mode Hint
                if isEditing && selectedFurnitureNode != nil {
                    VStack(spacing: 4) {
                        Text("Edit Mode")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• Drag: Move furniture")
                        Text("• Pinch: Scale")
                        Text("• Rotate: Turn")
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(8)
                    .padding()
                }
                
                // Bottom Controls
                HStack(spacing: 16) {
                    // Add Furniture Button
                    Button(action: {
                        if layoutManager.currentLayout == nil {
                            showingNewLayoutDialog = true
                        } else {
                            showingCatalogSheet = true
                        }
                    }) {
                        Label("Add Furniture", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if selectedFurnitureNode != nil {
                        // Edit Mode Toggle
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Label(isEditing ? "Done" : "Edit", systemImage: isEditing ? "checkmark.circle" : "pencil.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        // Delete Button
                        Button(action: {
                            if let node = selectedFurnitureNode {
                                layoutManager.removeFurniture(furnitureItem: node.furnitureItem)
                                selectedFurnitureNode = nil
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.large)
                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.9))
            }
            
            // Success Message
            if showSuccessMessage {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Layout saved successfully!")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNewLayoutDialog) {
            NewLayoutDialog(
                layoutName: $newLayoutName,
                isPresented: $showingNewLayoutDialog,
                onCreate: { name in
                    layoutManager.createNewLayout(name: name)
                    newLayoutName = ""
                    showingCatalogSheet = true
                }
            )
        }
        .sheet(isPresented: $showingCatalogSheet) {
            CatalogSelectionView(
                catalogItems: layoutManager.catalogItems,
                onSelectItem: { item in
                    // Add furniture to center of room on floor
                    let yPosition = item.defaultDimensions.height / 2.0 // Half height to sit on floor
                    layoutManager.addFurniture(catalogItem: item, at: SCNVector3(0, Float(yPosition), 0))
                    showingCatalogSheet = false
                }
            )
        }
    }
    
    private func saveLayout() {
        Task {
            do {
                try await layoutManager.saveCurrentLayout()
                await MainActor.run {
                    showSuccessMessage = true
                }
                
                // Hide success message after 2 seconds and return to main menu
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showSuccessMessage = false
                    dismiss()
                }
            } catch {
                print("Failed to save layout: \(error)")
            }
        }
    }
}

// MARK: - Interactive 3D Room View

struct Interactive3DRoomView: UIViewRepresentable {
    let furnitureNodes: [FurnitureNode]
    @Binding var selectedNode: FurnitureNode?
    @Binding var isEditing: Bool
    let onFurnitureMoved: (FurnitureItem, SCNVector3) -> Void
    let onFurnitureRotated: (FurnitureItem, SCNVector3) -> Void
    let onFurnitureScaled: (FurnitureItem, SCNVector3) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = UIColor.systemBackground
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        context.coordinator.setupRoom(scene: scene)
        context.coordinator.setupCamera(scene: scene)
        context.coordinator.setupLighting(scene: scene)
        context.coordinator.setupGestures(sceneView: sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateFurnitureNodes(scene: uiView.scene!, nodes: furnitureNodes)
        context.coordinator.isEditing = isEditing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: Interactive3DRoomView
        var cameraNode: SCNNode?
        var cameraOrbit: SCNNode?
        var cameraPivot: SCNNode?
        var isEditing: Bool = false
        
        private var cameraDistance: Float = 6.0
        private var cameraAngleX: Float = -25.0
        private var cameraAngleY: Float = 30.0
        
        init(_ parent: Interactive3DRoomView) {
            self.parent = parent
        }
        
        func setupRoom(scene: SCNScene) {
            // Simple box room - 4m x 6m x 2.5m
            let roomWidth: CGFloat = 4.0
            let roomLength: CGFloat = 6.0
            let roomHeight: CGFloat = 2.5
            
            // Floor
            let floorGeometry = SCNBox(width: roomWidth, height: 0.1, length: roomLength, chamferRadius: 0)
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            floorGeometry.materials = [floorMaterial]
            
            let floorNode = SCNNode(geometry: floorGeometry)
            floorNode.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(floorNode)
            
            // Back wall
            let backWall = SCNBox(width: roomWidth, height: roomHeight, length: 0.1, chamferRadius: 0)
            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
            backWall.materials = [wallMaterial]
            
            let backWallNode = SCNNode(geometry: backWall)
            backWallNode.position = SCNVector3(0, roomHeight/2, -roomLength/2)
            scene.rootNode.addChildNode(backWallNode)
            
            // Left wall
            let leftWall = SCNBox(width: 0.1, height: roomHeight, length: roomLength, chamferRadius: 0)
            leftWall.materials = [wallMaterial]
            let leftWallNode = SCNNode(geometry: leftWall)
            leftWallNode.position = SCNVector3(-roomWidth/2, roomHeight/2, 0)
            scene.rootNode.addChildNode(leftWallNode)
            
            // Right wall
            let rightWall = SCNBox(width: 0.1, height: roomHeight, length: roomLength, chamferRadius: 0)
            rightWall.materials = [wallMaterial]
            let rightWallNode = SCNNode(geometry: rightWall)
            rightWallNode.position = SCNVector3(roomWidth/2, roomHeight/2, 0)
            scene.rootNode.addChildNode(rightWallNode)
        }
        
        func setupCamera(scene: SCNScene) {
            cameraPivot = SCNNode()
            cameraPivot?.position = SCNVector3(0, 1.0, 0)
            
            cameraOrbit = SCNNode()
            
            cameraNode = SCNNode()
            cameraNode?.camera = SCNCamera()
            cameraNode?.camera?.zFar = 100
            cameraNode?.camera?.fieldOfView = 60
            
            scene.rootNode.addChildNode(cameraPivot!)
            cameraPivot?.addChildNode(cameraOrbit!)
            cameraOrbit?.addChildNode(cameraNode!)
            
            updateCameraPosition()
        }
        
        func updateCameraPosition() {
            cameraNode?.position = SCNVector3(0, 0, cameraDistance)
            cameraOrbit?.eulerAngles = SCNVector3(
                cameraAngleX * .pi / 180.0,
                cameraAngleY * .pi / 180.0,
                0
            )
        }
        
        func setupLighting(scene: SCNScene) {
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor(white: 0.5, alpha: 1.0)
            ambientLight.intensity = 600
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
            
            let mainLight = SCNLight()
            mainLight.type = .directional
            mainLight.intensity = 1200
            mainLight.castsShadow = true
            let mainLightNode = SCNNode()
            mainLightNode.light = mainLight
            mainLightNode.position = SCNVector3(3, 5, 3)
            mainLightNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(mainLightNode)
        }
        
        func updateFurnitureNodes(scene: SCNScene, nodes: [FurnitureNode]) {
            scene.rootNode.childNodes.filter { $0 is FurnitureNode }.forEach { $0.removeFromParentNode() }
            nodes.forEach { scene.rootNode.addChildNode($0) }
        }
        
        func setupGestures(sceneView: SCNView) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            sceneView.addGestureRecognizer(tap)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            sceneView.addGestureRecognizer(pan)
            
            let twoPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
            twoPan.minimumNumberOfTouches = 2
            sceneView.addGestureRecognizer(twoPan)
            
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            sceneView.addGestureRecognizer(pinch)
            
            let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            sceneView.addGestureRecognizer(rotation)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])
            
            // Remove previous selection highlight
            if let previousSelection = parent.selectedNode {
                removeSelectionHighlight(from: previousSelection)
            }
            
            if let hit = hitResults.first(where: { $0.node is FurnitureNode }) {
                let furnitureNode = hit.node as? FurnitureNode
                parent.selectedNode = furnitureNode
                
                // Add selection highlight
                if let selected = furnitureNode {
                    addSelectionHighlight(to: selected)
                }
            } else {
                parent.selectedNode = nil
            }
        }
        
        private func addSelectionHighlight(to node: FurnitureNode) {
            // Create a subtle outline effect
            if let geometry = node.geometry {
                let outlineMaterial = SCNMaterial()
                outlineMaterial.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
                outlineMaterial.emission.contents = UIColor.systemBlue.withAlphaComponent(0.5)
                
                // Store original materials
                node.setValue(geometry.materials, forKey: "originalMaterials")
                
                // Apply highlight
                var highlightedMaterials = geometry.materials
                highlightedMaterials.append(outlineMaterial)
                geometry.materials = highlightedMaterials
            }
        }
        
        private func removeSelectionHighlight(from node: FurnitureNode) {
            if let originalMaterials = node.value(forKey: "originalMaterials") as? [SCNMaterial],
               let geometry = node.geometry {
                geometry.materials = originalMaterials
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            
            if isEditing && parent.selectedNode != nil {
                // Move furniture with collision detection
                guard let selected = parent.selectedNode else { return }
                
                let moveSpeed: Float = 0.01
                var newPosition = SCNVector3(
                    selected.position.x + Float(translation.x) * moveSpeed,
                    0.5, // Keep furniture on floor (raised slightly to avoid z-fighting)
                    selected.position.z - Float(translation.y) * moveSpeed
                )
                
                // Apply collision detection with room boundaries
                newPosition = applyRoomBoundaries(position: newPosition, furniture: selected)
                
                selected.position = newPosition
                parent.onFurnitureMoved(selected.furnitureItem, newPosition)
                
                gesture.setTranslation(.zero, in: gesture.view)
            } else {
                // Rotate camera
                cameraAngleY += Float(translation.x) * 0.5
                cameraAngleX -= Float(translation.y) * 0.5
                cameraAngleX = max(-89, min(89, cameraAngleX))
                updateCameraPosition()
                
                gesture.setTranslation(.zero, in: gesture.view)
            }
        }
        
        private func applyRoomBoundaries(position: SCNVector3, furniture: FurnitureNode) -> SCNVector3 {
            // Room dimensions (from RoomConfiguration)
            let roomWidth: Float = 4.0
            let roomLength: Float = 6.0
            
            // Get furniture dimensions from catalog item
            let furnitureWidth = Float(furniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
            let furnitureDepth = Float(furniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
            
            var clampedPosition = position
            
            // Clamp X position (left-right walls)
            let minX = -roomWidth / 2.0 + furnitureWidth + 0.1 // 0.1 for wall thickness
            let maxX = roomWidth / 2.0 - furnitureWidth - 0.1
            clampedPosition.x = max(minX, min(maxX, position.x))
            
            // Clamp Z position (front-back walls)
            let minZ = -roomLength / 2.0 + furnitureDepth + 0.1
            let maxZ = roomLength / 2.0 - furnitureDepth - 0.1
            clampedPosition.z = max(minZ, min(maxZ, position.z))
            
            // Keep Y position at floor level
            clampedPosition.y = Float(furniture.catalogItem?.defaultDimensions.height ?? 1.0) / 2.0
            
            return clampedPosition
        }
        
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let pivot = cameraPivot else { return }
            let translation = gesture.translation(in: gesture.view)
            pivot.position.x -= Float(translation.x) * 0.01
            pivot.position.z += Float(translation.y) * 0.01
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if isEditing && parent.selectedNode != nil {
                guard let selected = parent.selectedNode else { return }
                let scale = Float(gesture.scale)
                let newScale = SCNVector3(
                    selected.scale.x * scale,
                    selected.scale.y * scale,
                    selected.scale.z * scale
                )
                selected.scale = newScale
                parent.onFurnitureScaled(selected.furnitureItem, newScale)
            } else {
                cameraDistance /= Float(gesture.scale)
                cameraDistance = max(3.0, min(12.0, cameraDistance))
                updateCameraPosition()
            }
            gesture.scale = 1.0
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard isEditing, let selected = parent.selectedNode else { return }
            let newRotation = SCNVector3(
                selected.eulerAngles.x,
                selected.eulerAngles.y + Float(gesture.rotation),
                selected.eulerAngles.z
            )
            selected.eulerAngles = newRotation
            parent.onFurnitureRotated(selected.furnitureItem, newRotation)
            gesture.rotation = 0
        }
    }
}

// MARK: - Catalog Selection Sheet

struct CatalogSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let catalogItems: [CatalogItem]
    let onSelectItem: (CatalogItem) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(catalogItems) { item in
                        Button(action: {
                            onSelectItem(item)
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 120)
                                    
                                    VStack {
                                        Image(systemName: furnitureIcon(for: item.type))
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue)
                                        Text(item.type)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    
                                    Text("\(String(format: "%.1f", item.defaultDimensions.width))m × \(String(format: "%.1f", item.defaultDimensions.depth))m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Furniture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func furnitureIcon(for type: String) -> String {
        switch type.lowercased() {
        case "sofa": return "sofa.fill"
        case "chair": return "chair.fill"
        case "table": return "table.furniture.fill"
        case "bed": return "bed.double.fill"
        case "storage": return "cabinet.fill"
        case "lighting": return "lightbulb.fill"
        default: return "cube.fill"
        }
    }
}

// MARK: - New Layout Dialog

struct NewLayoutDialog: View {
    @Binding var layoutName: String
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create New Layout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give your room layout a name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                TextField("e.g., Living Room, Bedroom", text: $layoutName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(layoutName)
                        isPresented = false
                    }
                    .disabled(layoutName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    RoomView()
        .environmentObject(LayoutManager())
}