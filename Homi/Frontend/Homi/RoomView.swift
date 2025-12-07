import SwiftUI
import SceneKit
import Photos

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
    let isViewOnly: Bool
    
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
    @State private var showingWallColorPicker = false
    @State private var showHints = true
    @State private var sceneViewRef: SCNView?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingDuplicateConfirmation = false
    @State private var successType: SuccessType?
    
    enum EditMode {
        case move, rotate, scale
    }

    init(isViewOnly: Bool = false) {
        self.isViewOnly = isViewOnly
    }

    enum SuccessType {
        case saved, duplicated, shareCreated
        
        var message: String {
            switch self {
            case .saved: return "Layout saved successfully!"
            case .duplicated: return "Layout duplicated successfully!"
            case .shareCreated: return "Share link copied to clipboard!"
            }
        }
    }
    
    var body: some View {
        ZStack {
            sceneView
            overlayContent
            successMessageView
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNewLayoutDialog) {
            newLayoutSheet
        }
        .sheet(isPresented: $showingCatalogSheet) {
            catalogSheet
        }
        .sheet(isPresented: $showingWallColorPicker) {
            wallColorSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Extracted Subviews
    
    private var sceneView: some View {
        RoomSceneView(
            furnitureNodes: layoutManager.furnitureNodes,
            selectedNode: $selectedFurnitureNode,
            isEditing: $isEditing,
            editMode: $editMode,
            isFirstPersonMode: $isFirstPersonMode,
            isEditingRoom: $isEditingRoom,
            roomConfig: $roomConfig,
            wallColor: layoutManager.wallColor,
            sceneViewRef: $sceneViewRef,
            isViewOnly: isViewOnly,
            onFurnitureMoved: { furnitureItem, position in
                if !isViewOnly {
                    layoutManager.updateFurniturePosition(furnitureItem, position: position)
                }
            },
            onFurnitureRotated: { furnitureItem, rotation in
                if !isViewOnly {
                    layoutManager.updateFurnitureRotation(furnitureItem, rotation: rotation)
                }
            },
            onFurnitureScaled: { furnitureItem, scale in
                if !isViewOnly {
                    layoutManager.updateFurnitureScale(furnitureItem, scale: scale)
                }
            }
        )
        .ignoresSafeArea()
    }
    
    private var overlayContent: some View {
        VStack {
            topControls
            Spacer()
            
            // View-only banner
            if isViewOnly {
                viewOnlyBanner
            }
            
            roomSizeEditor
            editModeSelector
            hintsView
            bottomControls
        }
    }
    
    private var viewOnlyBanner: some View {
        HStack {
            Image(systemName: "eye.fill")
            Text("View Only - Tap 'Save to My Layouts' to edit")
                .font(.subheadline)
        }
        .padding()
        .background(Color.blue.opacity(0.9))
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var topControls: some View {
        HStack {
            backButton
            Spacer()
            rightControls
        }
        .padding()
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
        .buttonStyle(.bordered)
        .fixedSize()
    }
    
    private var rightControls: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if !isViewOnly {
                if layoutManager.currentLayout != nil {
                    saveButton
                    shareButton
                }
                toolButtons
            } else {
                // View-only mode: only show camera controls
                firstPersonButton
                hintsToggleButton
            }
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            saveLayout()
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var shareButton: some View {
        Button(action: {
            shareLayout()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
            }
            .padding(8)
        }
        .buttonStyle(.bordered)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
    }
    
    private var toolButtons: some View {
        VStack(spacing: 8) {
            wallColorButton
            roomEditButton
            firstPersonButton
            hintsToggleButton
        }
    }
    
    private var wallColorButton: some View {
        Button(action: {
            showingWallColorPicker = true
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(layoutManager.wallColor))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    )
                Image(systemName: "paintbrush.fill")
                    .font(.caption)
            }
            .padding(8)
        }
        .buttonStyle(.bordered)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
    }
    
    private var roomEditButton: some View {
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
                .font(.body)
                .padding(8)
        }
        .buttonStyle(.bordered)
        .background(isEditingRoom ? Color.orange.opacity(0.2) : Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
    }
    
    private var firstPersonButton: some View {
        Button(action: {
            withAnimation {
                isFirstPersonMode.toggle()
            }
        }) {
            Image(systemName: isFirstPersonMode ? "camera.fill" : "person.fill")
                .font(.body)
                .padding(8)
        }
        .buttonStyle(.bordered)
        .background(isFirstPersonMode ? Color.blue.opacity(0.2) : Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
    }
    
    private var hintsToggleButton: some View {
        Button(action: {
            withAnimation {
                showHints.toggle()
            }
        }) {
            Image(systemName: showHints ? "eye.fill" : "eye.slash.fill")
                .font(.body)
                .padding(8)
        }
        .buttonStyle(.bordered)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .lineLimit(1)
        .fixedSize()
    }
    
    @ViewBuilder
    private var roomSizeEditor: some View {
        if isEditingRoom && !isViewOnly {
            VStack(spacing: 16) {
                Text("Edit Room Size")
                    .font(.headline)
                
                roomSizeControl(label: "Width:", value: $roomConfig.width, range: EditableRoom.minSize...EditableRoom.maxSize)
                roomSizeControl(label: "Length:", value: $roomConfig.length, range: EditableRoom.minSize...EditableRoom.maxSize)
                roomSizeControl(label: "Height:", value: $roomConfig.height, range: 2.0...5.0)
     
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
    }
    
    private func roomSizeControl(label: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)
            Slider(value: value, in: range, step: 0.1)
                .onChange(of: value.wrappedValue) { oldValue, newValue in
                    value.wrappedValue = max(range.lowerBound, min(range.upperBound, (newValue * 10).rounded() / 10))
                }
            TextField("", value: value, format: .number.precision(.fractionLength(1)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .multilineTextAlignment(.center)
            Text("m").foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var editModeSelector: some View {
        if isEditing && selectedFurnitureNode != nil && !isEditingRoom && !isViewOnly {
            HStack(spacing: 12) {
                EditModeButton(mode: .move, currentMode: editMode, icon: "arrow.up.and.down.and.arrow.left.and.right", label: "Move") {
                    editMode = .move
                }
                EditModeButton(mode: .rotate, currentMode: editMode, icon: "arrow.clockwise", label: "Rotate") {
                    editMode = .rotate
                }
                EditModeButton(mode: .scale, currentMode: editMode, icon: "arrow.up.left.and.arrow.down.right", label: "Scale") {
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
    }
    
    @ViewBuilder
    private var hintsView: some View {
        if showHints {
            Group {
                if isViewOnly {
                    HintView(title: "View Only Mode", icon: "eye.fill", hints: ["Explore the room freely", "Tap 'Save to My Layouts' to edit"], color: .blue)
                } else if isEditingRoom {
                    HintView(title: "Room Editor", icon: "house.fill", hints: ["Adjust sliders to resize room", "Furniture stays in place", "Tap house icon to exit"], color: .orange)
                } else if !isEditing && !showingCatalogSheet && selectedFurnitureNode == nil && !isFirstPersonMode {
                    HintView(title: "Camera Controls", hints: ["Drag: Rotate camera", "Two fingers: Pan", "Pinch: Zoom"])
                } else if isFirstPersonMode && !isEditing {
                    HintView(title: "First Person View", icon: "person.fill.viewfinder", hints: ["Drag: Look around", "Walls turn transparent"], color: .blue)
                } else if !isEditing && selectedFurnitureNode != nil {
                    HintView(title: "Furniture Selected", hints: ["Tap 'Edit' to modify"], color: .blue)
                } else if isEditing && selectedFurnitureNode != nil {
                    currentEditModeHint
                }
            }
        }
    }
    
    private var currentEditModeHint: some View {
        let (title, hints) = editModeHintContent
        return HintView(title: title, hints: hints, color: .green)
    }
    
    private var editModeHintContent: (String, [String]) {
        switch editMode {
        case .move:
            return ("Move Mode", ["Drag to move furniture", "Collision detection active"])
        case .rotate:
            return ("Rotate Mode", ["Drag left/right to rotate", "Smooth 360° rotation"])
        case .scale:
            return ("Scale Mode", ["Drag up/down to scale", "Maintains proportions"])
        }
    }
    
    private var bottomControls: some View {
        HStack(spacing: 16) {
            if isViewOnly {
                // View-only mode: Show duplicate button
                duplicateButtonForViewOnly
            } else if !isEditingRoom {
                // Normal mode: Show add/edit/delete
                addFurnitureButton
                if selectedFurnitureNode != nil {
                    editButton
                    deleteButton
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    private var duplicateButtonForViewOnly: some View {
        Button(action: {
            duplicateSharedLayout()
        }) {
            Label("Save to My Layouts", systemImage: "square.and.arrow.down")
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    private var addFurnitureButton: some View {
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
    }
    
    private var editButton: some View {
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
    }
    
    private var deleteButton: some View {
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
    
    @ViewBuilder
    private var successMessageView: some View {
        if let type = successType {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(type.message)
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
    
    private var newLayoutSheet: some View {
        NewLayoutDialog(
            layoutName: $newLayoutName,
            isPresented: $showingNewLayoutDialog,
            onCreate: { name, wallColor in
                layoutManager.createNewLayout(name: name, wallColor: wallColor)
                newLayoutName = ""
                showingCatalogSheet = true
            }
        )
    }
    
    private var catalogSheet: some View {
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
    
    private var wallColorSheet: some View {
        WallColorPickerSheet(
            selectedColor: Binding(
                get: { Color(layoutManager.wallColor) },
                set: { layoutManager.wallColor = UIColor($0) }
            )
        )
    }
    
    private func shareLayout() {
        Task {
            do {
                guard let layout = layoutManager.currentLayout,
                    let layoutId = layout.id else {
                    print("No layout to share")
                    return
                }
                
                let shareId = try await layoutManager.createShareLink(layoutId: layoutId)
                let url = URL(string: "homi://view/\(shareId)")!
                
                await MainActor.run {
                    // Copy to clipboard
                    UIPasteboard.general.string = url.absoluteString
                    
                    withAnimation {
                        successType = .shareCreated
                    }
                }
                
                // Hide success message after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation {
                        successType = nil
                    }
                }
                
                // Then show share sheet
                await MainActor.run {
                    self.shareURL = url
                    self.showingShareSheet = true
                }
            } catch {
                print("Failed to create share link: \(error)")
            }
        }
    }
    
    private func duplicateSharedLayout() {
        Task {
            do {
                let _ = try await layoutManager.duplicateLayout()
                await MainActor.run {
                    withAnimation {
                        successType = .duplicated
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation {
                        successType = nil
                    }
                    // Optionally dismiss back to home
                    dismiss()
                }
            } catch {
                print("❌ Failed to duplicate layout:", error)
            }
        }
    }
    
    private func saveLayout() {
        Task {
            do {
                try await layoutManager.saveCurrentLayout()
                await MainActor.run {
                    withAnimation {
                        successType = .saved
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation {
                        successType = nil
                    }
                }
            } catch {
                print("Failed to save layout: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    let wallColor: UIColor
    @Binding var sceneViewRef: SCNView?
    let isViewOnly: Bool
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
        
        // Store reference to scene view
        DispatchQueue.main.async {
            sceneViewRef = sceneView
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateFurnitureNodes(scene: uiView.scene!, nodes: furnitureNodes)
        context.coordinator.isEditing = isEditing
        context.coordinator.editMode = editMode
        context.coordinator.updateRoomSize(scene: uiView.scene!, config: roomConfig)
        context.coordinator.updateWallColor(scene: uiView.scene!, color: wallColor)
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
        private let dimensionLabelName = "dimensionLabel"
        
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
            createRoomGeometry(scene: scene, config: parent.roomConfig, wallColor: parent.wallColor)
        }
        
        private func makeWallMaterial(color: UIColor) -> SCNMaterial {
            let m = SCNMaterial()
            m.diffuse.contents = color
            m.lightingModel = .phong
            m.transparency = 1.0
            m.transparencyMode = .aOne
            m.isDoubleSided = true
            m.writesToDepthBuffer = true
            m.readsFromDepthBuffer = true
            return m
        }

        func createRoomGeometry(scene: SCNScene, config: EditableRoom) {
            createRoomGeometry(scene: scene, config: config, wallColor: parent.wallColor)
        }
        
        func createRoomGeometry(scene: SCNScene, config: EditableRoom, wallColor: UIColor) {
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
            
            // Wall material with custom color
            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = wallColor
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
        
        func updateWallColor(scene: SCNScene, color: UIColor) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            
            let walls: [SCNNode?] = [frontWallNode, backWallNode, leftWallNode, rightWallNode]
            
            for wall in walls {
                guard let wall = wall, let geometry = wall.geometry else { continue }
                
                // Update all materials on this wall
                for material in geometry.materials {
                    material.diffuse.contents = color
                }
            }
            
            SCNTransaction.commit()
        }
        
        func updateWallTransparency(scene: SCNScene) {
            // 1. Normalize Angle (0-360)
            var angle = Int(cameraAngleY) % 360
            if angle < 0 { angle += 360 }
            
            // 2. Reset: Start with all walls visible
            frontWallNode?.isHidden = false
            backWallNode?.isHidden = false
            leftWallNode?.isHidden = false
            rightWallNode?.isHidden = false
            
            if isFirstPersonMode {
                // In First Person, show everything (or add custom logic)
                return
            }
            
            // 3. Independent Checks (No 'else') with Overlap
            // We use a +/- 60 degree buffer so that at corners (like 45°), 
            // BOTH adjacent walls will be hidden.
            
            // Front Wall (0°): Hide if camera is between 300° and 60°
            if angle > 300 || angle < 60 {
                frontWallNode?.isHidden = true
            }
            
            // Right Wall (90°): Hide if camera is between 30° and 150°
            if angle > 30 && angle < 150 {
                rightWallNode?.isHidden = true
            }
            
            // Back Wall (180°): Hide if camera is between 120° and 240°
            if angle > 120 && angle < 240 {
                backWallNode?.isHidden = true
            }
            
            // Left Wall (270°): Hide if camera is between 210° and 330°
            if angle > 210 && angle < 330 {
                leftWallNode?.isHidden = true
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
                removeDimensionLabel(from: previousSelection)
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
                    addDimensionLabel(to: furniture)
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
            
            // CASE 1: Editing Furniture (Move / Rotate / Scale)
            if isEditing && parent.selectedNode != nil {
                if parent.isViewOnly {
                    // In view-only mode, editing gestures do nothing
                    gesture.setTranslation(.zero, in: gesture.view)
                    return
                }

                guard let selected = parent.selectedNode,
                    let scene = sceneView?.scene else { return }

                switch editMode {
                case .move:
                    let moveSpeed: Float = 0.01
                    // Calculate new position based on drag
                    let newPosition = SCNVector3(
                        selected.position.x + Float(translation.x) * moveSpeed,
                        selected.position.y,
                        selected.position.z - Float(translation.y) * moveSpeed
                    )
                    
                    // Apply collision logic to keep it inside walls
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
                    // Dragging UP scales up, DOWN scales down
                    let scaleDelta = 1.0 + Float(-translation.y) * scaleSpeed
                    let newScale = SCNVector3(
                        selected.scale.x * scaleDelta,
                        selected.scale.y * scaleDelta,
                        selected.scale.z * scaleDelta
                    )
                    // Clamp scale between 0.5x and 3.0x
                    let clampedScale = SCNVector3(
                        max(0.5, min(3.0, newScale.x)),
                        max(0.5, min(3.0, newScale.y)),
                        max(0.5, min(3.0, newScale.z))
                    )
                    selected.scale = clampedScale
                    
                    addDimensionLabel(to: selected)

                    if gesture.state == .ended {
                        parent.onFurnitureScaled(selected.furnitureItem, clampedScale)
                    }
                }
                
                gesture.setTranslation(.zero, in: gesture.view)
                
            // CASE 2: First Person Camera Look
            } else if isFirstPersonMode {
                firstPersonAngleY -= Float(translation.x) * 0.005
                firstPersonAngleX -= Float(translation.y) * 0.005
                // Limit looking up/down so you don't flip over
                firstPersonAngleX = max(-1.5, min(1.5, firstPersonAngleX))
                
                firstPersonCamera?.eulerAngles = SCNVector3(firstPersonAngleX, firstPersonAngleY, 0)
                
                gesture.setTranslation(.zero, in: gesture.view)
                
                // Update walls (optional in FP mode, but good for consistency)
                if let scene = sceneView?.scene {
                    updateWallTransparency(scene: scene)
                }
                
            // CASE 3: Orbit Camera (Standard View)
            } else {
                // Rotate Camera around the room center
                cameraAngleY -= Float(translation.x) * 0.5
                cameraAngleX -= Float(translation.y) * 0.5
                
                // Clamp vertical angle so you can't go under the floor
                cameraAngleX = max(-89, min(-5, cameraAngleX))
                
                updateCameraPosition()
                gesture.setTranslation(.zero, in: gesture.view)
                
                // CRITICAL: Update wall visibility immediately while rotating
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
                if parent.isViewOnly {
                    gesture.scale = 1.0
                    return
                }
                
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

                addDimensionLabel(to: selected)
                
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
        
        func addDimensionLabel(to furniture: FurnitureNode) {
            // Remove any existing label first
            removeDimensionLabel(from: furniture)
            
            // Get bounding box dimensions
            let (min, max) = furniture.boundingBox
            let width = (max.x - min.x) * furniture.scale.x
            let height = (max.y - min.y) * furniture.scale.y
            let depth = (max.z - min.z) * furniture.scale.z
            
            // Create dimension text
            let dimensionText = String(format: "%.2fm × %.2fm × %.2fm", width, height, depth)
            let textGeometry = SCNText(string: dimensionText, extrusionDepth: 0.01)
            
            // Style the text
            if let font = UIFont(name: "Helvetica-Bold", size: 18) {
                textGeometry.font = font
            }
            textGeometry.flatness = 0.1
            
            let textMaterial = SCNMaterial()
            textMaterial.diffuse.contents = UIColor.black
            textMaterial.specular.contents = UIColor.black
            
            let outlineMaterial = SCNMaterial()
            outlineMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.8)
            
            textGeometry.materials = [textMaterial, outlineMaterial]
            
            // Create text node
            let textNode = SCNNode(geometry: textGeometry)
            textNode.name = dimensionLabelName
            
            // Scale down the text
            textNode.scale = SCNVector3(0.004, 0.004, 0.004)
            
            // Center the text horizontally
            let textBounds = textGeometry.boundingBox
            let textWidth = textBounds.max.x - textBounds.min.x
            textNode.pivot = SCNMatrix4MakeTranslation(textWidth / 2, 0, 0)
            
            // Position above the furniture
            textNode.position = SCNVector3(0, max.y * furniture.scale.y + 0.15, 0)
            
            // Make it face the camera (billboard constraint)
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = .Y
            textNode.constraints = [billboardConstraint]
            
            // Add to furniture node
            furniture.addChildNode(textNode)
        }

        /// Remove the dimension label from furniture
        func removeDimensionLabel(from furniture: FurnitureNode) {
            furniture.childNode(withName: dimensionLabelName, recursively: false)?.removeFromParentNode()
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

// MARK: - Wall Color Picker Sheet
struct WallColorPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedColor: Color
    
    private let wallColorOptions: [(name: String, color: Color)] = [
        ("White", Color(UIColor(white: 0.95, alpha: 1.0))),
        ("Beige", Color(red: 0.96, green: 0.96, blue: 0.86)),
        ("Light Gray", Color(UIColor(white: 0.85, alpha: 1.0))),
        ("Cream", Color(red: 1.0, green: 0.99, blue: 0.94)),
        ("Pale Blue", Color(red: 0.88, green: 0.94, blue: 0.98)),
        ("Light Green", Color(red: 0.92, green: 0.98, blue: 0.92)),
        ("Soft Pink", Color(red: 0.98, green: 0.92, blue: 0.94)),
        ("Light Yellow", Color(red: 0.99, green: 0.98, blue: 0.88)),
        ("Lavender", Color(red: 0.94, green: 0.92, blue: 0.98)),
        ("Peach", Color(red: 0.98, green: 0.94, blue: 0.90)),
        ("Mint", Color(red: 0.94, green: 0.98, blue: 0.96)),
        ("Sky", Color(red: 0.90, green: 0.96, blue: 0.98))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    VStack(spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedColor)
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                    
                    // Color Grid
                    VStack(spacing: 16) {
                        Text("Select Wall Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(wallColorOptions, id: \.name) { option in
                                WallColorPickerOption(
                                    name: option.name,
                                    color: option.color,
                                    isSelected: selectedColor == option.color
                                ) {
                                    selectedColor = option.color
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
            }
            .navigationTitle("Wall Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WallColorPickerOption: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(Color.white).padding(4))
                            }
                        }
                    )
                
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

prefix func - (v: SCNVector3) -> SCNVector3 {
    SCNVector3(-v.x, -v.y, -v.z)
}

func - (a: SCNVector3, b: SCNVector3) -> SCNVector3 {
    SCNVector3(a.x - b.x, a.y - b.y, a.z - b.z)
}
