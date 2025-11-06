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
    @State private var editMode: EditMode = .move
    
    enum EditMode {
        case move, rotate, scale
    }
    
    var body: some View {
        ZStack {
            // 3D Scene View
            Interactive3DRoomView(
                furnitureNodes: layoutManager.furnitureNodes,
                selectedNode: $selectedFurnitureNode,
                isEditing: $isEditing,
                editMode: $editMode,
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
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
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
                
                // Edit Mode Selector
                if isEditing && selectedFurnitureNode != nil {
                    HStack(spacing: 12) {
                        EditModeButton(
                            mode: .move,
                            currentMode: editMode,
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            label: "Move"
                        ) {
                            editMode = .move
                        }
                        
                        EditModeButton(
                            mode: .rotate,
                            currentMode: editMode,
                            icon: "arrow.clockwise",
                            label: "Rotate"
                        ) {
                            editMode = .rotate
                        }
                        
                        EditModeButton(
                            mode: .scale,
                            currentMode: editMode,
                            icon: "arrow.up.left.and.arrow.down.right",
                            label: "Scale"
                        ) {
                            editMode = .scale
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Hints
                if !isEditing && !showingCatalogSheet && selectedFurnitureNode == nil && !isFirstPersonMode {
                    HintView(
                        title: "Camera Controls",
                        hints: [
                            "Drag: Rotate camera",
                            "Two fingers: Pan",
                            "Pinch: Zoom"
                        ]
                    )
                } else if isFirstPersonMode && !isEditing {
                    HintView(
                        title: "First Person View",
                        icon: "person.fill.viewfinder",
                        hints: [
                            "Drag: Look around",
                            "Tap person icon to exit"
                        ],
                        color: .blue
                    )
                } else if !isEditing && selectedFurnitureNode != nil {
                    HintView(
                        title: "Furniture Selected",
                        hints: ["Tap 'Edit' to modify"],
                        color: .blue
                    )
                } else if isEditing && selectedFurnitureNode != nil {
                    HintView(
                        title: editMode == .move ? "Move Mode" : (editMode == .rotate ? "Rotate Mode" : "Scale Mode"),
                        hints: editMode == .move ? [
                            "Drag slowly to move",
                            "Furniture snaps to walls"
                        ] : editMode == .rotate ? [
                            "Drag left/right to rotate",
                            "Smooth 360° rotation"
                        ] : [
                            "Pinch to scale",
                            "Maintains proportions"
                        ],
                        color: .green
                    )
                }
                
                // Bottom Controls
                HStack(spacing: 16) {
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
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    editMode = .move
                                }
                            }
                        }) {
                            Label(isEditing ? "Done" : "Edit", systemImage: isEditing ? "checkmark.circle" : "pencil.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
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
                    layoutManager.addFurniture(catalogItem: item, at: SCNVector3(0, 0, 0))
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
                    withAnimation {
                        showSuccessMessage = true
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation {
                        showSuccessMessage = false
                    }
                    dismiss()
                }
            } catch {
                print("Failed to save layout: \(error)")
            }
        }
    }
}

// MARK: - Helper Views

struct EditModeButton: View {
    let mode: RoomView.EditMode
    let currentMode: RoomView.EditMode
    let icon: String
    let label: String
    let action: () -> Void
    
    var isSelected: Bool {
        mode == currentMode
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HintView: View {
    let title: String
    var icon: String? = nil
    let hints: [String]
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
            }
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
            ForEach(hints, id: \.self) { hint in
                Text("• \(hint)")
            }
        }
        .font(.caption2)
        .foregroundColor(.white)
        .padding(8)
        .background(color == .blue ? Color.blue.opacity(0.8) : (color == .green ? Color.green.opacity(0.7) : Color.black.opacity(0.6)))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - Interactive 3D Room View

struct Interactive3DRoomView: UIViewRepresentable {
    let furnitureNodes: [FurnitureNode]
    @Binding var selectedNode: FurnitureNode?
    @Binding var isEditing: Bool
    @Binding var editMode: RoomView.EditMode
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
        context.coordinator.editMode = editMode
        
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
        var editMode: RoomView.EditMode = .move
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
            let roomWidth: CGFloat = 8.0
            let roomLength: CGFloat = 10.0
            let roomHeight: CGFloat = 3.0
            
            // Floor
            let floorGeometry = SCNBox(width: roomWidth, height: 0.1, length: roomLength, chamferRadius: 0)
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            floorMaterial.lightingModel = .physicallyBased
            floorMaterial.roughness.contents = 0.8
            floorGeometry.materials = [floorMaterial]
            
            let floorNode = SCNNode(geometry: floorGeometry)
            floorNode.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(floorNode)
            
            // Walls
            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
            wallMaterial.lightingModel = .physicallyBased
            wallMaterial.roughness.contents = 0.9
            
            // Back wall
            let backWall = SCNBox(width: roomWidth, height: roomHeight, length: 0.1, chamferRadius: 0)
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
            cameraPivot?.position = SCNVector3(0, 1.5, 0)
            
            cameraOrbit = SCNNode()
            cameraNode = SCNNode()
            cameraNode?.camera = SCNCamera()
            cameraNode?.camera?.zFar = 100
            cameraNode?.camera?.fieldOfView = 60
            
            scene.rootNode.addChildNode(cameraPivot!)
            cameraPivot?.addChildNode(cameraOrbit!)
            cameraOrbit?.addChildNode(cameraNode!)
            
            firstPersonCamera = SCNNode()
            firstPersonCamera?.camera = SCNCamera()
            firstPersonCamera?.camera?.zFar = 100
            firstPersonCamera?.camera?.fieldOfView = 70
            firstPersonCamera?.position = SCNVector3(0, 1.6, 0)
            scene.rootNode.addChildNode(firstPersonCamera!)
            
            updateCameraPosition()
            sceneView?.pointOfView = cameraNode
        }
        
        func switchToFirstPersonView() {
            firstPersonAngleX = 0.0
            firstPersonAngleY = 0.0
            firstPersonCamera?.position = SCNVector3(0, 1.6, 0)
            firstPersonCamera?.eulerAngles = SCNVector3(0, 0, 0)
            sceneView?.pointOfView = firstPersonCamera
        }
        
        func switchToOrbitView() {
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
            let existingFurniture = scene.rootNode.childNodes.compactMap { $0 as? FurnitureNode }
            
            // Add only new nodes that don't exist yet
            for node in nodes where !existingFurniture.contains(where: { $0.furnitureItem.id == node.furnitureItem.id }) {
                scene.rootNode.addChildNode(node)
            }
            
            // Remove deleted ones
            for old in existingFurniture where !nodes.contains(where: { $0.furnitureItem.id == old.furnitureItem.id }) {
                old.removeFromParentNode()
            }
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
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])
            
            if let previousSelection = parent.selectedNode {
                removeSelectionHighlight(from: previousSelection)
            }
            
            if let hit = hitResults.first {
                var currentNode = hit.node
                var furnitureNode: FurnitureNode?
                
                // Walk up the node hierarchy to find a FurnitureNode
                while currentNode.parent != nil {
                    if let furniture = currentNode as? FurnitureNode {
                        furnitureNode = furniture
                        break
                    }
                    if let furniture = currentNode.parent as? FurnitureNode {
                        furnitureNode = furniture
                        break
                    }
                    currentNode = currentNode.parent!
                }
                
                if let furniture = furnitureNode {
                    parent.selectedNode = furniture
                    addSelectionHighlight(to: furniture)
                } else {
                    parent.selectedNode = nil
                }
            } else {
                parent.selectedNode = nil
            }
        }
        
        private func addSelectionHighlight(to node: FurnitureNode) {
            node.enumerateChildNodes { (child, _) in
                if let geometry = child.geometry {
                    let originalMaterials = geometry.materials
                    child.setValue(originalMaterials, forKey: "originalMaterials")
                    
                    let highlightedMaterials = originalMaterials.map { material -> SCNMaterial in
                        let newMaterial = material.copy() as! SCNMaterial
                        newMaterial.emission.contents = UIColor.systemBlue.withAlphaComponent(0.3)
                        return newMaterial
                    }
                    geometry.materials = highlightedMaterials
                }
            }
        }
        
        private func removeSelectionHighlight(from node: FurnitureNode) {
            node.enumerateChildNodes { (child, _) in
                if let originalMaterials = child.value(forKey: "originalMaterials") as? [SCNMaterial],
                   let geometry = child.geometry {
                    geometry.materials = originalMaterials
                }
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            
            if isEditing && parent.selectedNode != nil {
                guard let selected = parent.selectedNode,
                      let scene = sceneView?.scene else { return }

                switch editMode {
                case .move:
                    guard let selected = parent.selectedNode else { return }

                    let moveSpeed: Float = 0.05
                    let translationX = Float(translation.x) * moveSpeed
                    let translationZ = -Float(translation.y) * moveSpeed

                    // Compute desired target
                    let target = SCNVector3(
                        selected.position.x + translationX,
                        selected.position.y,
                        selected.position.z + translationZ
                    )

                    // Apply wall/furniture collision
                    let clampedTarget = applyCollisionDetection(position: target, furniture: selected, scene: scene)

                    // Smooth interpolation only for this node
                    let smoothing: Float = 0.5
                    selected.position.x += (clampedTarget.x - selected.position.x) * smoothing
                    selected.position.z += (clampedTarget.z - selected.position.z) * smoothing

                    parent.onFurnitureMoved(selected.furnitureItem, selected.position)
                case .rotate:
                    let rotationSpeed: Float = 0.01
                    let newRotation = SCNVector3(
                        selected.eulerAngles.x,
                        selected.eulerAngles.y - Float(translation.x) * rotationSpeed,
                        selected.eulerAngles.z
                    )
                    selected.eulerAngles = newRotation
                    parent.onFurnitureRotated(selected.furnitureItem, newRotation)
                    
                case .scale:
                    let scaleSpeed: Float = 0.01
                    let scaleDelta = 1.0 + Float(-translation.y) * scaleSpeed
                    let newScale = SCNVector3(
                        selected.scale.x * scaleDelta,
                        selected.scale.y * scaleDelta,
                        selected.scale.z * scaleDelta
                    )
                    let clampedScale = SCNVector3(
                        max(0.5, min(3.0, newScale.x)),
                        max(0.5, min(3.0, newScale.y)),
                        max(0.5, min(3.0, newScale.z))
                    )
                    selected.scale = clampedScale
                    parent.onFurnitureScaled(selected.furnitureItem, clampedScale)
                }
                
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
            
            // Wall collision - keep furniture inside room
            let minX = -roomWidth / 2.0 + furnitureWidth + 0.1
            let maxX = roomWidth / 2.0 - furnitureWidth - 0.1
            clampedPosition.x = max(minX, min(maxX, position.x))
            
            let minZ = -roomLength / 2.0 + furnitureDepth + 0.1
            let maxZ = roomLength / 2.0 - furnitureDepth - 0.1
            clampedPosition.z = max(minZ, min(maxZ, position.z))
            clampedPosition.y = 0
            
            // Furniture-to-furniture collision detection
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
                
                // Check for overlap
                if thisMaxX > otherMinX && thisMinX < otherMaxX &&
                   thisMaxZ > otherMinZ && thisMinZ < otherMaxZ {
                    
                    // Calculate overlap on each axis
                    let overlapX = min(thisMaxX - otherMinX, otherMaxX - thisMinX)
                    let overlapZ = min(thisMaxZ - otherMinZ, otherMaxZ - thisMinZ)
                    
                    // Push away on the axis with smallest overlap
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
                    
                    // Re-clamp to room boundaries
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
            if isEditing && parent.selectedNode != nil && editMode == .scale {
                guard let selected = parent.selectedNode else { return }
                let scale = Float(gesture.scale)
                let newScale = SCNVector3(
                    selected.scale.x * scale,
                    selected.scale.y * scale,
                    selected.scale.z * scale
                )
                let clampedScale = SCNVector3(
                    max(0.5, min(3.0, newScale.x)),
                    max(0.5, min(3.0, newScale.y)),
                    max(0.5, min(3.0, newScale.z))
                )
                selected.scale = clampedScale
                parent.onFurnitureScaled(selected.furnitureItem, clampedScale)
            } else if !isFirstPersonMode {
                cameraDistance /= Float(gesture.scale)
                cameraDistance = max(5.0, min(20.0, cameraDistance))
                updateCameraPosition()
            }
            gesture.scale = 1.0
        }
    }
}

// MARK: - Supporting Views

struct CatalogSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let catalogItems: [CatalogItem]
    let onSelectItem: (CatalogItem) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(catalogItems) { item in
                        Button(action: { onSelectItem(item) }) {
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
                    Button("Cancel") { dismiss() }
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
                    Button("Cancel") { isPresented = false }
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