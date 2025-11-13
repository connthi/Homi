// RoomView.swift - Enhanced 3D interaction with room editing

import SwiftUI
import SceneKit

// MARK: - Room Configuration Model
struct EditableRoom {
    var width: Float
    var length: Float
    var height: Float
    
    static let `default` = EditableRoom(width: 8.0, length: 10.0, height: 3.0)
    
    // Constraints
    static let minSize: Float = 3.0
    static let maxSize: Float = 20.0
}

// MARK: - Main Room View
struct RoomView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @Environment(\.dismiss) var dismiss
    @State private var showingNewLayoutDialog = false
    @State private var showingCatalogSheet = false
    @State private var newLayoutName = ""
    @State private var selectedFurnitureNode: FurnitureNode?
    @State private var isEditing = false
    @State private var isFirstPersonMode = false
    @State private var showSuccessMessage = false
    @State private var editMode: EditMode = .move
    @State private var isEditingRoom = false
    @State private var roomConfig = EditableRoom.default
    
    enum EditMode {
        case move, rotate, scale
    }
    
    var body: some View {
        ZStack {
            // 3D Scene View
            RoomSceneView(
                furnitureNodes: layoutManager.furnitureNodes,
                selectedNode: $selectedFurnitureNode,
                isEditing: $isEditing,
                editMode: $editMode,
                isFirstPersonMode: $isFirstPersonMode,
                isEditingRoom: $isEditingRoom,
                roomConfig: $roomConfig,
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
                    
                    // Room Edit Toggle
                    Button(action: {
                        withAnimation {
                            isEditingRoom.toggle()
                            if isEditingRoom {
                                isEditing = false
                                selectedFurnitureNode = nil
                            }
                        }
                    }) {
                        Image(systemName: isEditingRoom ? "house.fill" : "house")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .background(isEditingRoom ? Color.orange.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    
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
                
                // Room Size Editor
                if isEditingRoom {
                    VStack(spacing: 16) {
                        Text("Edit Room Size")
                            .font(.headline)
                        
                        // Width control
                        HStack {
                            Text("Width:")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $roomConfig.width, in: EditableRoom.minSize...EditableRoom.maxSize, step: 0.1)
                                .onChange(of: roomConfig.width) { v in
                                    roomConfig.width = max(EditableRoom.minSize, min(EditableRoom.maxSize, (v * 10).rounded() / 10))
                                }
                            TextField("", value: $roomConfig.width, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .onChange(of: roomConfig.width) { v in
                                    roomConfig.width = max(EditableRoom.minSize, min(EditableRoom.maxSize, (v * 10).rounded() / 10))
                                }
                            Text("m").foregroundColor(.secondary)
                        }

                        // Length control
                        HStack {
                            Text("Length:")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $roomConfig.length, in: EditableRoom.minSize...EditableRoom.maxSize, step: 0.1)
                                .onChange(of: roomConfig.length) { v in
                                    roomConfig.length = max(EditableRoom.minSize, min(EditableRoom.maxSize, (v * 10).rounded() / 10))
                                }
                            TextField("", value: $roomConfig.length, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .onChange(of: roomConfig.length) { v in
                                    roomConfig.length = max(EditableRoom.minSize, min(EditableRoom.maxSize, (v * 10).rounded() / 10))
                                }
                            Text("m").foregroundColor(.secondary)
                        }

                        // Height control
                        HStack {
                            Text("Height:")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $roomConfig.height, in: 2.0...5.0, step: 0.1)
                                .onChange(of: roomConfig.height) { v in
                                    roomConfig.height = max(2.0, min(5.0, (v * 10).rounded() / 10))
                                }
                            TextField("", value: $roomConfig.height, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .onChange(of: roomConfig.height) { v in
                                    roomConfig.height = max(2.0, min(5.0, (v * 10).rounded() / 10))
                                }
                            Text("m").foregroundColor(.secondary)
                        }
             
                        Button("Reset to Default") {
                            withAnimation {
                                roomConfig = EditableRoom.default
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                
                // Edit Mode Selector
                if isEditing && selectedFurnitureNode != nil && !isEditingRoom {
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
                if isEditingRoom {
                    HintView(
                        title: "Room Editor",
                        icon: "house.fill",
                        hints: [
                            "Adjust sliders to resize room",
                            "Furniture stays in place",
                            "Tap house icon to exit"
                        ],
                        color: .orange
                    )
                } else if !isEditing && !showingCatalogSheet && selectedFurnitureNode == nil && !isFirstPersonMode {
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
                            "Front wall turns transparent"
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
                            "Drag to move furniture",
                            "Collision detection active"
                        ] : editMode == .rotate ? [
                            "Drag left/right to rotate",
                            "Smooth 360° rotation"
                        ] : [
                            "Drag up/down to scale",
                            "Maintains proportions"
                        ],
                        color: .green
                    )
                }
                
                // Bottom Controls
                HStack(spacing: 16) {
                    if !isEditingRoom {
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
            // Enhanced catalog picker with search and categories
            CatalogPickerView(
                catalogItems: layoutManager.catalogItems,
                onSelectItem: { item in
                    layoutManager.addFurniture(catalogItem: item, at: SCNVector3(0, 0, 0))
                    showingCatalogSheet = false
                },
                onDismiss: {
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

// MARK: - Enhanced Catalog Picker
struct CatalogPickerView: View {
    let catalogItems: [CatalogItem]
    let onSelectItem: (CatalogItem) -> Void
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Chair", "Speaker", "Bed", "Bookshelf", "Couch", "Desk", "Table"]
    
    var filteredItems: [CatalogItem] {
        let categoryFiltered = selectedCategory == "All" 
            ? catalogItems 
            : catalogItems.filter { $0.type == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search furniture...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
                
                Divider()
                
                // Results
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No furniture found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search or category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredItems) { item in
                                FurniturePickerRow(item: item) {
                                    onSelectItem(item)
                                }
                                
                                if item.id != filteredItems.last?.id {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Furniture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

struct FurniturePickerRow: View {
    let item: CatalogItem
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: furnitureIcon(for: item.type))
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(item.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "cube")
                                .font(.caption2)
                            Text("\(String(format: "%.1f", item.defaultDimensions.width))×\(String(format: "%.1f", item.defaultDimensions.depth))m")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Add button
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func furnitureIcon(for type: String) -> String {
        switch type.lowercased() {
        case "sofa", "couch": return "sofa.fill"
        case "chair": return "chair.fill"
        case "table": return "table.furniture.fill"
        case "bed": return "bed.double.fill"
        case "storage", "bookshelf": return "cabinet.fill"
        case "lighting", "speaker": return "lightbulb.fill"
        case "desk": return "desk.fill"
        default: return "cube.fill"
        }
    }
}

// MARK: - 3D Scene View with Transparent Walls
struct RoomSceneView: UIViewRepresentable {
    let furnitureNodes: [FurnitureNode]
    @Binding var selectedNode: FurnitureNode?
    @Binding var isEditing: Bool
    @Binding var editMode: RoomView.EditMode
    @Binding var isFirstPersonMode: Bool
    @Binding var isEditingRoom: Bool
    @Binding var roomConfig: EditableRoom
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
        context.coordinator.updateRoomSize(scene: uiView.scene!, config: roomConfig)
        context.coordinator.updateWallTransparency(scene: uiView.scene!)
        
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
        let parent: RoomSceneView
        weak var sceneView: SCNView?
        var cameraNode: SCNNode?
        var cameraOrbit: SCNNode?
        var cameraPivot: SCNNode?
        var firstPersonCamera: SCNNode?
        var isEditing: Bool = false
        var editMode: RoomView.EditMode = .move
        var isFirstPersonMode: Bool = false
        
        var floorNode: SCNNode?
        var frontWallNode: SCNNode?
        var backWallNode: SCNNode?
        var leftWallNode: SCNNode?
        var rightWallNode: SCNNode?
        
        private var cameraDistance: Float = 12.0
        private var cameraAngleX: Float = -30.0
        private var cameraAngleY: Float = 30.0
        private var firstPersonAngleX: Float = 0.0
        private var firstPersonAngleY: Float = 0.0
        
        init(_ parent: RoomSceneView) {
            self.parent = parent
        }
        
        func setupRoom(scene: SCNScene) {
            createRoomGeometry(scene: scene, config: parent.roomConfig)
        }
        
        private func makeWallMaterial() -> SCNMaterial {
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
            m.lightingModel = .phong
            m.transparency = 1.0
            m.transparencyMode = .aOne
            m.isDoubleSided = true
            m.writesToDepthBuffer = true
            m.readsFromDepthBuffer = true
            return m
        }

        func createRoomGeometry(scene: SCNScene, config: EditableRoom) {
            floorNode?.removeFromParentNode()
            frontWallNode?.removeFromParentNode()
            backWallNode?.removeFromParentNode()
            leftWallNode?.removeFromParentNode()
            rightWallNode?.removeFromParentNode()
            
            let roomWidth = CGFloat(config.width)
            let roomLength = CGFloat(config.length)
            let roomHeight = CGFloat(config.height)
            
            // Floor
            let floorGeometry = SCNBox(width: roomWidth, height: 0.1, length: roomLength, chamferRadius: 0)
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            floorMaterial.lightingModel = .physicallyBased
            floorMaterial.roughness.contents = 0.8
            floorGeometry.materials = [floorMaterial]
            
            floorNode = SCNNode(geometry: floorGeometry)
            floorNode?.position = SCNVector3(0, 0, 0)
            floorNode?.name = "floor"
            scene.rootNode.addChildNode(floorNode!)
            
            // Wall material
            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
            wallMaterial.lightingModel = .physicallyBased
            wallMaterial.roughness.contents = 0.9
            wallMaterial.transparency = 1.0
            wallMaterial.transparencyMode = .aOne
            wallMaterial.isDoubleSided = true
            wallMaterial.writesToDepthBuffer = true
            wallMaterial.readsFromDepthBuffer = true
            
            // Front wall
            let frontWall = SCNBox(width: roomWidth, height: roomHeight, length: 0.1, chamferRadius: 0)
            frontWall.materials = [wallMaterial.copy() as! SCNMaterial]
            frontWallNode = SCNNode(geometry: frontWall)
            frontWallNode?.position = SCNVector3(0, roomHeight/2, roomLength/2)
            frontWallNode?.name = "frontWall"
            scene.rootNode.addChildNode(frontWallNode!)
            
            // Back wall
            let backWall = SCNBox(width: roomWidth, height: roomHeight, length: 0.1, chamferRadius: 0)
            backWall.materials = [wallMaterial.copy() as! SCNMaterial]
            backWallNode = SCNNode(geometry: backWall)
            backWallNode?.position = SCNVector3(0, roomHeight/2, -roomLength/2)
            backWallNode?.name = "backWall"
            scene.rootNode.addChildNode(backWallNode!)
            
            // Left wall
            let leftWall = SCNBox(width: 0.1, height: roomHeight, length: roomLength, chamferRadius: 0)
            leftWall.materials = [wallMaterial.copy() as! SCNMaterial]
            leftWallNode = SCNNode(geometry: leftWall)
            leftWallNode?.position = SCNVector3(-roomWidth/2, roomHeight/2, 0)
            leftWallNode?.name = "leftWall"
            scene.rootNode.addChildNode(leftWallNode!)
            
            // Right wall
            let rightWall = SCNBox(width: 0.1, height: roomHeight, length: roomLength, chamferRadius: 0)
            rightWall.materials = [wallMaterial.copy() as! SCNMaterial]
            rightWallNode = SCNNode(geometry: rightWall)
            rightWallNode?.position = SCNVector3(roomWidth/2, roomHeight/2, 0)
            rightWallNode?.name = "rightWall"
            scene.rootNode.addChildNode(rightWallNode!)
        }
        
        func updateRoomSize(scene: SCNScene, config: EditableRoom) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            
            let roomWidth = CGFloat(config.width)
            let roomLength = CGFloat(config.length)
            let roomHeight = CGFloat(config.height)
            
            if let floor = floorNode, let geometry = floor.geometry as? SCNBox {
                geometry.width = roomWidth
                geometry.length = roomLength
            }
            
            if let frontWall = frontWallNode, let geometry = frontWall.geometry as? SCNBox {
                geometry.width = roomWidth
                geometry.height = roomHeight
                frontWall.position = SCNVector3(0, roomHeight/2, roomLength/2)
            }
            
            if let backWall = backWallNode, let geometry = backWall.geometry as? SCNBox {
                geometry.width = roomWidth
                geometry.height = roomHeight
                backWall.position = SCNVector3(0, roomHeight/2, -roomLength/2)
            }
            
            if let leftWall = leftWallNode, let geometry = leftWall.geometry as? SCNBox {
                geometry.height = roomHeight
                geometry.length = roomLength
                leftWall.position = SCNVector3(-roomWidth/2, roomHeight/2, 0)
            }
            
            if let rightWall = rightWallNode, let geometry = rightWall.geometry as? SCNBox {
                geometry.height = roomHeight
                geometry.length = roomLength
                rightWall.position = SCNVector3(roomWidth/2, roomHeight/2, 0)
            }
            
            SCNTransaction.commit()
        }
        
        func updateWallTransparency(scene: SCNScene) {
            guard let camera = sceneView?.pointOfView else { return }

            // Camera world-space info
            let camPos = camera.presentation.worldPosition
            let camFwd = camera.presentation.worldFront // <- forward is worldFront (no negation)

            // Walls with their outward normals in world space
            let walls: [(name: String, node: SCNNode?, normal: SCNVector3)] = [
                ("frontWall", frontWallNode, SCNVector3(0, 0,  1)), // z = +L/2
                ("backWall",  backWallNode,  SCNVector3(0, 0, -1)), // z = -L/2
                ("leftWall",  leftWallNode,  SCNVector3(-1, 0, 0)), // x = -W/2
                ("rightWall", rightWallNode, SCNVector3( 1, 0, 0))  // x = +W/2
            ]

            // Helper to apply transparency to all materials on a node
            func setTransparency(_ node: SCNNode, _ alpha: CGFloat) {
                guard let geom = node.geometry else { return }
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25

                // Render transparent walls AFTER opaque stuff
                node.renderingOrder = (alpha < 1.0) ? 100 : 0

                // Update all materials
                var mats = geom.materials
                for i in 0..<mats.count {
                    let m = mats[i]
                    m.transparency = alpha
                    m.transparencyMode = .aOne
                    m.isDoubleSided = true
                    // Critical: don’t write depth when transparent so it doesn’t block what’s behind
                    m.writesToDepthBuffer = (alpha >= 1.0)
                    m.readsFromDepthBuffer = true
                    mats[i] = m
                }
                geom.materials = mats
                SCNTransaction.commit()
            }

            // Determine which walls should be ghosted
            for (name, node, normal) in walls {
                guard let wall = node else { continue }

                let wallPos = wall.presentation.worldPosition

                // Vector from wall to camera
                let wallToCam = SCNVector3(camPos.x - wallPos.x, camPos.y - wallPos.y, camPos.z - wallPos.z)

                // Is the camera in front of this wall's outward face?
                // (i.e., on the side the normal points toward)
                let inFront = dot(wallToCam, normal) > 0

                // Is the camera roughly looking at the room through this wall?
                // (forward has some component opposite the wall normal)
                let lookingTowardWall = dot(camFwd, normal) < -0.15

                // Reasonable proximity check so far walls don't flicker
                let dist = length(wallToCam)
                let closeEnough = dist < 30.0

                let shouldBeTransparent: Bool
                if isFirstPersonMode {
                    shouldBeTransparent = (name == "frontWall")
                } else {
                    shouldBeTransparent = inFront && lookingTowardWall && closeEnough
                }

                setTransparency(wall, shouldBeTransparent ? 0.2 : 1.0)
            }
        }

        @inline(__always) func dot(_ a: SCNVector3, _ b: SCNVector3) -> Float {
            a.x*b.x + a.y*b.y + a.z*b.z
        }
        @inline(__always) func length(_ v: SCNVector3) -> Float {
            sqrtf(v.x*v.x + v.y*v.y + v.z*v.z)
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
            if let scene = sceneView?.scene { updateWallTransparency(scene: scene) }
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
            ambientLight.color = UIColor(white: 0.6, alpha: 1.0)
            ambientLight.intensity = 800
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
            
            let mainLight = SCNLight()
            mainLight.type = .directional
            mainLight.intensity = 1500
            mainLight.castsShadow = true
            mainLight.shadowMode = .deferred
            let mainLightNode = SCNNode()
            mainLightNode.light = mainLight
            mainLightNode.position = SCNVector3(5, 10, 5)
            mainLightNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(mainLightNode)
        }
        
        func updateFurnitureNodes(scene: SCNScene, nodes: [FurnitureNode]) {
            let existingFurniture = scene.rootNode.childNodes.compactMap { $0 as? FurnitureNode }
            
            // Add new furniture nodes
            for node in nodes where !existingFurniture.contains(where: { $0.furnitureItem.id == node.furnitureItem.id }) {
                // Force the node to setup its geometry immediately
                node.setupGeometryIfNeeded()
                scene.rootNode.addChildNode(node)
            }
            
            // Remove deleted furniture nodes
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
                    let moveSpeed: Float = 0.01
                    let newPosition = SCNVector3(
                        selected.position.x + Float(translation.x) * moveSpeed,
                        selected.position.y,
                        selected.position.z - Float(translation.y) * moveSpeed
                    )
                    
                    let clampedPosition = applyCollisionDetection(position: newPosition, furniture: selected, scene: scene)
                    selected.position = clampedPosition
                    
                    if gesture.state == .ended {
                        parent.onFurnitureMoved(selected.furnitureItem, clampedPosition)
                    }
                    
                case .rotate:
                    let rotationSpeed: Float = 0.01
                    let newRotation = SCNVector3(
                        selected.eulerAngles.x,
                        selected.eulerAngles.y - Float(translation.x) * rotationSpeed,
                        selected.eulerAngles.z
                    )
                    selected.eulerAngles = newRotation
                    
                    if gesture.state == .ended {
                        parent.onFurnitureRotated(selected.furnitureItem, newRotation)
                    }
                    
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
                    
                    if gesture.state == .ended {
                        parent.onFurnitureScaled(selected.furnitureItem, clampedScale)
                    }
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
                
                // Update wall transparency in first person mode
                if let scene = sceneView?.scene {
                    updateWallTransparency(scene: scene)
                }
                
            } else {
                cameraAngleY -= Float(translation.x) * 0.5
                cameraAngleX -= Float(translation.y) * 0.5
                cameraAngleX = max(-89, min(89, cameraAngleX))
                updateCameraPosition()
                gesture.setTranslation(.zero, in: gesture.view)
                
                // Update wall transparency during camera rotation
                if let scene = sceneView?.scene {
                    updateWallTransparency(scene: scene)
                }
            }
        }
        
        private func applyCollisionDetection(position: SCNVector3, furniture: FurnitureNode, scene: SCNScene) -> SCNVector3 {
            let config = parent.roomConfig
            let roomWidth = config.width
            let roomLength = config.length
            
            let furnitureWidth = Float(furniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
            let furnitureDepth = Float(furniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
            
            var clampedPosition = position
            
            let wallPadding: Float = 0.05
            let minX = -roomWidth / 2.0 + furnitureWidth + wallPadding
            let maxX = roomWidth / 2.0 - furnitureWidth - wallPadding
            clampedPosition.x = max(minX, min(maxX, position.x))
            
            let minZ = -roomLength / 2.0 + furnitureDepth + wallPadding
            let maxZ = roomLength / 2.0 - furnitureDepth - wallPadding
            clampedPosition.z = max(minZ, min(maxZ, position.z))
            clampedPosition.y = 0
            
            let allFurniture = scene.rootNode.childNodes.compactMap { $0 as? FurnitureNode }.filter { $0 !== furniture }
            
            for otherFurniture in allFurniture {
                let otherWidth = Float(otherFurniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
                let otherDepth = Float(otherFurniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
                
                let thisMinX = clampedPosition.x - furnitureWidth
                let thisMaxX = clampedPosition.x + furnitureWidth
                let thisMinZ = clampedPosition.z - furnitureDepth
                let thisMaxZ = clampedPosition.z + furnitureDepth
                
                let otherMinX = otherFurniture.position.x - otherWidth
                let otherMaxX = otherFurniture.position.x + otherWidth
                let otherMinZ = otherFurniture.position.z - otherDepth
                let otherMaxZ = otherFurniture.position.z + otherDepth
                
                if thisMaxX > otherMinX && thisMinX < otherMaxX &&
                   thisMaxZ > otherMinZ && thisMinZ < otherMaxZ {
                    
                    let overlapX = min(thisMaxX - otherMinX, otherMaxX - thisMinX)
                    let overlapZ = min(thisMaxZ - otherMinZ, otherMaxZ - thisMinZ)
                    
                    if overlapX < overlapZ {
                        if clampedPosition.x > otherFurniture.position.x {
                            clampedPosition.x = otherMaxX + furnitureWidth + 0.05
                        } else {
                            clampedPosition.x = otherMinX - furnitureWidth - 0.05
                        }
                    } else {
                        if clampedPosition.z > otherFurniture.position.z {
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
            
            // Update wall transparency during camera pan
            if let scene = sceneView?.scene {
                updateWallTransparency(scene: scene)
            }
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
                
                if gesture.state == .ended {
                    parent.onFurnitureScaled(selected.furnitureItem, clampedScale)
                }
            } else if !isFirstPersonMode {
                cameraDistance /= Float(gesture.scale)
                cameraDistance = max(5.0, min(25.0, cameraDistance))
                updateCameraPosition()
                
                if let scene = sceneView?.scene {
                    updateWallTransparency(scene: scene)
                }
            }
            gesture.scale = 1.0
        }
        
        private func distance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
    }
}

// MARK: - Supporting Views

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
        .background(
            color == .blue ? Color.blue.opacity(0.8) :
            color == .green ? Color.green.opacity(0.7) :
            color == .orange ? Color.orange.opacity(0.8) :
            Color.black.opacity(0.6)
        )
        .cornerRadius(8)
        .padding()
    }
}

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

prefix func - (v: SCNVector3) -> SCNVector3 {
    return SCNVector3(-v.x, -v.y, -v.z)
}