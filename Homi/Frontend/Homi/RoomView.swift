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
    @State private var isFirstPersonMode = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        ZStack {
            // 3D Scene View
            Interactive3DRoomView(
                furnitureNodes: layoutManager.furnitureNodes,
                selectedNode: $selectedFurnitureNode,
                isEditing: $isEditing,
                isFirstPersonMode: $isFirstPersonMode,
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
                    
                    // First Person View Button
                    Button(action: {
                        withAnimation {
                            isFirstPersonMode.toggle()
                        }
                    }) {
                        Image(systemName: isFirstPersonMode ? "camera.fill" : "person.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .background(isFirstPersonMode ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    
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
                if !isEditing && !showingCatalogSheet && selectedFurnitureNode == nil && !isFirstPersonMode {
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
                
                // First Person Mode Hint
                if isFirstPersonMode && !isEditing {
                    VStack(spacing: 4) {
                        Image(systemName: "person.fill.viewfinder")
                            .font(.title2)
                        Text("First Person View")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• Drag: Look around")
                        Text("• Tap person icon to exit")
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
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
    @Binding var isFirstPersonMode: Bool
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
        
        // Store reference to sceneView in coordinator
        context.coordinator.sceneView = sceneView
        
        context.coordinator.setupRoom(scene: scene)
        context.coordinator.setupCamera(scene: scene)
        context.coordinator.setupLighting(scene: scene)
        context.coordinator.setupGestures(sceneView: sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateFurnitureNodes(scene: uiView.scene!, nodes: furnitureNodes)
        context.coordinator.isEditing = isEditing
        
        // Switch camera mode
        if isFirstPersonMode != context.coordinator.isFirstPersonMode {
            context.coordinator.isFirstPersonMode = isFirstPersonMode
            if isFirstPersonMode {
                context.coordinator.switchToFirstPersonView()
            } else {
                context.coordinator.switchToOrbitView()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: Interactive3DRoomView
        weak var sceneView: SCNView?
        var cameraNode: SCNNode?
        var cameraOrbit: SCNNode?
        var cameraPivot: SCNNode?
        var firstPersonCamera: SCNNode?
        var isEditing: Bool = false
        var isFirstPersonMode: Bool = false
        
        private var cameraDistance: Float = 10.0
        private var cameraAngleX: Float = -25.0
        private var cameraAngleY: Float = 30.0
        private var firstPersonAngleX: Float = 0.0
        private var firstPersonAngleY: Float = 0.0
        
        init(_ parent: Interactive3DRoomView) {
            self.parent = parent
        }
        
        func setupRoom(scene: SCNScene) {
            // Larger room - 8m x 10m x 3m
            let roomWidth: CGFloat = 8.0
            let roomLength: CGFloat = 10.0
            let roomHeight: CGFloat = 3.0
            
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
            // Orbit camera setup (centered on room center)
            cameraPivot = SCNNode()
            cameraPivot?.position = SCNVector3(0, 1.5, 0)
            
            cameraOrbit = SCNNode()
            
            cameraNode = SCNNode()
            cameraNode?.camera = SCNCamera()
            cameraNode?.camera?.zFar = 100
            cameraNode?.camera?.fieldOfView = 60
            
            scene.rootNode.addChildNode(cameraPivot!)
            cameraPivot?.addChildNode(cameraOrbit!)
            cameraOrbit?.addChildNode(cameraNode!)
            
            // First person camera setup (at center of room, eye level)
            firstPersonCamera = SCNNode()
            firstPersonCamera?.camera = SCNCamera()
            firstPersonCamera?.camera?.zFar = 100
            firstPersonCamera?.camera?.fieldOfView = 70
            firstPersonCamera?.position = SCNVector3(0, 1.6, 0)
            scene.rootNode.addChildNode(firstPersonCamera!)
            
            // Set initial camera
            updateCameraPosition()
            sceneView?.pointOfView = cameraNode
        }
        
        func switchToFirstPersonView() {
            // Reset first person angles to look forward
            firstPersonAngleX = 0.0
            firstPersonAngleY = 0.0
            
            // Position first person camera at center of room at head height
            firstPersonCamera?.position = SCNVector3(0, 1.6, 0)
            firstPersonCamera?.eulerAngles = SCNVector3(0, 0, 0)
            
            // Switch the active camera
            sceneView?.pointOfView = firstPersonCamera
        }
        
        func switchToOrbitView() {
            // Switch back to orbit camera
            updateCameraPosition()
            sceneView?.pointOfView = cameraNode
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
            mainLightNode.position = SCNVector3(5, 8, 5)
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
            
            // Add scroll wheel support for macOS (zoom)
            #if targetEnvironment(macCatalyst)
            let scrollRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleScroll(_:)))
            scrollRecognizer.allowedScrollTypesMask = .continuous
            sceneView.addGestureRecognizer(scrollRecognizer)
            #endif
        }
        
        #if targetEnvironment(macCatalyst)
        @objc func handleScroll(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            
            if isFirstPersonMode {
                // In first person, scroll zooms field of view
                firstPersonCamera?.camera?.fieldOfView -= Double(translation.y * 0.1)
                firstPersonCamera?.camera?.fieldOfView = max(30, min(110, firstPersonCamera?.camera?.fieldOfView ?? 70))
            } else {
                // In orbit, scroll zooms distance
                cameraDistance += Float(translation.y) * 0.05
                cameraDistance = max(5.0, min(20.0, cameraDistance))
                updateCameraPosition()
            }
            
            gesture.setTranslation(.zero, in: gesture.view)
        }
        #endif
        
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
            if let geometry = node.geometry {
                let outlineMaterial = SCNMaterial()
                outlineMaterial.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
                outlineMaterial.emission.contents = UIColor.systemBlue.withAlphaComponent(0.5)
                
                node.setValue(geometry.materials, forKey: "originalMaterials")
                
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
                guard let selected = parent.selectedNode,
                      let scene = sceneView?.scene else { return }

                let moveSpeed: Float = 0.01
                var newPosition = SCNVector3(
                    selected.position.x + Float(translation.x) * moveSpeed,
                    selected.position.y,
                    selected.position.z - Float(translation.y) * moveSpeed
                )
                
                newPosition = applyCollisionDetection(position: newPosition, furniture: selected, scene: scene)
                
                selected.position = newPosition
                parent.onFurnitureMoved(selected.furnitureItem, newPosition)
                
                gesture.setTranslation(.zero, in: gesture.view)
            } else if isFirstPersonMode {
                firstPersonAngleY -= Float(translation.x) * 0.5
                firstPersonAngleX -= Float(translation.y) * 0.5
                
                firstPersonAngleX = max(-89, min(89, firstPersonAngleX))
                
                firstPersonCamera?.eulerAngles = SCNVector3(
                    firstPersonAngleX * .pi / 180.0,
                    firstPersonAngleY * .pi / 180.0,
                    0
                )
                
                gesture.setTranslation(.zero, in: gesture.view)
            } else {
                cameraAngleY -= Float(translation.x) * 0.5
                cameraAngleX -= Float(translation.y) * 0.5
                cameraAngleX = max(-89, min(89, cameraAngleX))
                updateCameraPosition()
                
                gesture.setTranslation(.zero, in: gesture.view)
            }
        }
        
        private func applyCollisionDetection(position: SCNVector3, furniture: FurnitureNode, scene: SCNScene) -> SCNVector3 {
            let roomWidth: Float = 8.0
            let roomLength: Float = 10.0
            
            let furnitureWidth = Float(furniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
            let furnitureDepth = Float(furniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
            
            var clampedPosition = position
            
            let minX = -roomWidth / 2.0 + furnitureWidth + 0.1
            let maxX = roomWidth / 2.0 - furnitureWidth - 0.1
            clampedPosition.x = max(minX, min(maxX, position.x))
            
            let minZ = -roomLength / 2.0 + furnitureDepth + 0.1
            let maxZ = roomLength / 2.0 - furnitureDepth - 0.1
            clampedPosition.z = max(minZ, min(maxZ, position.z))
            
            clampedPosition.y = Float(furniture.catalogItem?.defaultDimensions.height ?? 1.0) / 2.0
            
            let allFurniture = scene.rootNode.childNodes.filter { $0 is FurnitureNode && $0 !== furniture }
            
            for otherNode in allFurniture {
                guard let otherFurniture = otherNode as? FurnitureNode else { continue }
                
                let otherWidth = Float(otherFurniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
                let otherDepth = Float(otherFurniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
                
                let thisMinX = clampedPosition.x - furnitureWidth
                let thisMaxX = clampedPosition.x + furnitureWidth
                let thisMinZ = clampedPosition.z - furnitureDepth
                let thisMaxZ = clampedPosition.z + furnitureDepth
                
                let otherMinX = otherNode.position.x - otherWidth
                let otherMaxX = otherNode.position.x + otherWidth
                let otherMinZ = otherNode.position.z - otherDepth
                let otherMaxZ = otherNode.position.z + otherDepth
                
                if thisMaxX > otherMinX && thisMinX < otherMaxX &&
                   thisMaxZ > otherMinZ && thisMinZ < otherMaxZ {
                    let overlapX = min(thisMaxX - otherMinX, otherMaxX - thisMinX)
                    let overlapZ = min(thisMaxZ - otherMinZ, otherMaxZ - thisMinZ)
                    
                    if overlapX < overlapZ {
                        if clampedPosition.x > otherNode.position.x {
                            clampedPosition.x = otherMaxX + furnitureWidth + 0.05
                        } else {
                            clampedPosition.x = otherMinX - furnitureWidth - 0.05
                        }
                    } else {
                        if clampedPosition.z > otherNode.position.z {
                            clampedPosition.z = otherMaxZ + furnitureDepth + 0.05
                        } else {
                            clampedPosition.z = otherMinZ - furnitureDepth - 0.05
                        }
                    }
                    
                    clampedPosition.x = max(minX, min(maxX, clampedPosition.x))
                    clampedPosition.z = max(minZ, min(maxZ, clampedPosition.z))
                }
            }
            
            return clampedPosition
        }
        
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard !isFirstPersonMode, let pivot = cameraPivot else { return }
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
            } else if !isFirstPersonMode {
                cameraDistance /= Float(gesture.scale)
                cameraDistance = max(5.0, min(20.0, cameraDistance))
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