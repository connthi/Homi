import SwiftUI
import SceneKit

struct RoomView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @State private var showingNewLayoutDialog = false
    @State private var showingSaveDialog = false
    @State private var newLayoutName = ""
    @State private var selectedFurnitureNode: FurnitureNode?
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 3D Scene View
                SceneKitView(
                    furnitureNodes: layoutManager.furnitureNodes,
                    selectedNode: $selectedFurnitureNode,
                    isEditing: $isEditing,
                    onFurnitureAdded: { catalogItem, position in
                        layoutManager.addFurniture(catalogItem: catalogItem, at: position)
                    },
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
                        if layoutManager.currentLayout == nil {
                            Button("New Layout") {
                                showingNewLayoutDialog = true
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Save") {
                                showingSaveDialog = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Edit") {
                                isEditing.toggle()
                            }
                            .buttonStyle(.bordered)
                        }
                        
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
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom Controls
                    if isEditing {
                        EditingControlsView(
                            selectedNode: selectedFurnitureNode,
                            onDelete: {
                                if let node = selectedFurnitureNode {
                                    layoutManager.removeFurniture(furnitureItem: node.furnitureItem)
                                    selectedFurnitureNode = nil
                                }
                            }
                        )
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewLayoutDialog) {
            NewLayoutDialog(
                layoutName: $newLayoutName,
                isPresented: $showingNewLayoutDialog,
                onCreate: { name in
                    layoutManager.createNewLayout(name: name)
                    newLayoutName = ""
                }
            )
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveLayoutDialog(
                layoutName: $newLayoutName,
                isPresented: $showingSaveDialog,
                onSave: { name in
                    Task {
                        try? await layoutManager.saveCurrentLayout()
                    }
                }
            )
        }
    }
}

struct SceneKitView: UIViewRepresentable {
    let furnitureNodes: [FurnitureNode]
    @Binding var selectedNode: FurnitureNode?
    @Binding var isEditing: Bool
    let onFurnitureAdded: (CatalogItem, SCNVector3) -> Void
    let onFurnitureMoved: (FurnitureItem, SCNVector3) -> Void
    let onFurnitureRotated: (FurnitureItem, SCNVector3) -> Void
    let onFurnitureScaled: (FurnitureItem, SCNVector3) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = UIColor.systemBackground
        
        // Create scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Setup room
        setupRoom(scene: scene)
        
        // Setup camera
        setupCamera(scene: scene)
        
        // Setup lighting
        setupLighting(scene: scene)
        
        // Add furniture nodes
        updateFurnitureNodes(scene: scene)
        
        // Setup gestures
        setupGestures(sceneView: sceneView, context: context)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updateFurnitureNodes(scene: uiView.scene!)
    }
    
    private func setupRoom(scene: SCNScene) {
        let roomConfig = RoomConfiguration.defaultRoom
        
        // Floor
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0.1
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor.lightGray
        floorGeometry.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(0, -roomConfig.height/2, 0)
        scene.rootNode.addChildNode(floorNode)
        
        // Walls
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor.white
        
        // Back wall
        let backWallGeometry = SCNBox(width: CGFloat(roomConfig.width), height: CGFloat(roomConfig.height), length: CGFloat(roomConfig.wallThickness), chamferRadius: 0)
        backWallGeometry.materials = [wallMaterial]
        let backWallNode = SCNNode(geometry: backWallGeometry)
        backWallNode.position = SCNVector3(0, 0, -roomConfig.length/2)
        scene.rootNode.addChildNode(backWallNode)
        
        // Left wall
        let leftWallGeometry = SCNBox(width: CGFloat(roomConfig.wallThickness), height: CGFloat(roomConfig.height), length: CGFloat(roomConfig.length), chamferRadius: 0)
        leftWallGeometry.materials = [wallMaterial]
        let leftWallNode = SCNNode(geometry: leftWallGeometry)
        leftWallNode.position = SCNVector3(-roomConfig.width/2, 0, 0)
        scene.rootNode.addChildNode(leftWallNode)
        
        // Right wall
        let rightWallGeometry = SCNBox(width: CGFloat(roomConfig.wallThickness), height: CGFloat(roomConfig.height), length: CGFloat(roomConfig.length), chamferRadius: 0)
        rightWallGeometry.materials = [wallMaterial]
        let rightWallNode = SCNNode(geometry: rightWallGeometry)
        rightWallNode.position = SCNVector3(roomConfig.width/2, 0, 0)
        scene.rootNode.addChildNode(rightWallNode)
    }
    
    private func setupCamera(scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 2, 3)
        cameraNode.eulerAngles = SCNVector3(-Float.pi/6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting(scene: SCNScene) {
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white
        ambientLight.intensity = 300
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(0, 5, 0)
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi/4, 0, 0)
        scene.rootNode.addChildNode(directionalLightNode)
    }
    
    private func updateFurnitureNodes(scene: SCNScene) {
        // Remove existing furniture nodes
        scene.rootNode.childNodes.filter { $0 is FurnitureNode }.forEach { $0.removeFromParentNode() }
        
        // Add new furniture nodes
        furnitureNodes.forEach { furnitureNode in
            scene.rootNode.addChildNode(furnitureNode)
        }
    }
    
    private func setupGestures(sceneView: SCNView, context: Context) {
        // Tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Pan gesture for moving furniture
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        // Rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: SceneKitView
        
        init(_ parent: SceneKitView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let sceneView = gesture.view as! SCNView
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])
            
            if let hit = hitResults.first {
                if let furnitureNode = hit.node as? FurnitureNode {
                    parent.selectedNode = furnitureNode
                } else {
                    parent.selectedNode = nil
                }
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard parent.isEditing, let selectedNode = parent.selectedNode else { return }
            
            let sceneView = gesture.view as! SCNView
            let translation = gesture.translation(in: sceneView)
            
            // Convert 2D translation to 3D movement
            let newPosition = SCNVector3(
                selectedNode.position.x + Float(translation.x) * 0.01,
                selectedNode.position.y,
                selectedNode.position.z - Float(translation.y) * 0.01
            )
            
            selectedNode.position = newPosition
            parent.onFurnitureMoved(selectedNode.furnitureItem, newPosition)
            
            gesture.setTranslation(.zero, in: sceneView)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard parent.isEditing, let selectedNode = parent.selectedNode else { return }
            
            let scale = gesture.scale
            let newScale = SCNVector3(
                selectedNode.scale.x * Float(scale),
                selectedNode.scale.y * Float(scale),
                selectedNode.scale.z * Float(scale)
            )
            
            selectedNode.scale = newScale
            parent.onFurnitureScaled(selectedNode.furnitureItem, newScale)
            
            gesture.scale = 1.0
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard parent.isEditing, let selectedNode = parent.selectedNode else { return }
            
            let rotation = gesture.rotation
            let newRotation = SCNVector3(
                selectedNode.eulerAngles.x,
                selectedNode.eulerAngles.y + Float(rotation),
                selectedNode.eulerAngles.z
            )
            
            selectedNode.eulerAngles = newRotation
            parent.onFurnitureRotated(selectedNode.furnitureItem, newRotation)
            
            gesture.rotation = 0
        }
    }
}

struct EditingControlsView: View {
    let selectedNode: FurnitureNode?
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if selectedNode != nil {
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            Spacer()
            
            Text("Tap furniture to select, drag to move, pinch to scale, rotate to turn")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
        }
    }
}

struct NewLayoutDialog: View {
    @Binding var layoutName: String
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Layout Name", text: $layoutName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Layout")
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
                }
            }
        }
    }
}

struct SaveLayoutDialog: View {
    @Binding var layoutName: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Layout Name", text: $layoutName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Save Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(layoutName)
                        isPresented = false
                    }
                    .disabled(layoutName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    RoomView()
        .environmentObject(LayoutManager())
}
