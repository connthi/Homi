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
        .onAppear {
            // Check if we entered a "New Project" (no active layout)
            // and trigger the setup dialog immediately.
            if !isViewOnly && layoutManager.currentLayout == nil {
                // A tiny delay ensures the view transition finishes before the sheet pops up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingNewLayoutDialog = true
                }
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
        HStack(alignment: .top) { // <--- FIXED: Align content to the top
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .buttonStyle(.bordered)
            .fixedSize()
            .padding(.top, 4) // Optional: Tiny tweak to align perfectly with right buttons
            
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
                let url = URL(string: "https://homi.app/view/\(shareId)")!
                
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
        
        init(_ parent: RoomSceneView) { self.parent = parent }
        
        // MARK: - "Clean Look" Lighting Setup
        // In RoomView.swift -> Coordinator -> setupLighting

        func setupLighting(scene: SCNScene) {
            scene.rootNode.childNodes.filter { $0.light != nil }.forEach { $0.removeFromParentNode() }
            
            // 1. Ambient Light (Keep this low for contrast)
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor(white: 0.8, alpha: 1.0)
            ambientLight.intensity = 200 // Slightly reduced (was 250)
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
            
            // 2. Room Fill Light (THE CULPRIT)
            // This was making the middle too bright. We lower it and move it higher.
            let omniLight = SCNLight()
            omniLight.type = .omni
            omniLight.intensity = 150 // HUGE DROP (was 300) -> Fixes the "bright middle"
            omniLight.color = UIColor(white: 0.95, alpha: 1.0)
            let omniNode = SCNNode()
            omniNode.light = omniLight
            omniNode.position = SCNVector3(0, 6.0, 0) // Moved up higher (was 3.0)
            scene.rootNode.addChildNode(omniNode)
            
            // 3. Directional Light (The "Good Shadows")
            let dirLight = SCNLight()
            dirLight.type = .directional
            dirLight.intensity = 600 // Reduced (was 800) to stop white furninture from glowing
            dirLight.castsShadow = false 
            
            let dirNode = SCNNode()
            dirNode.light = dirLight
            dirNode.position = SCNVector3(5, 10, 10)
            dirNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(dirNode)
        }
        
        // MARK: - Geometry Setup
        func setupRoom(scene: SCNScene) { createRoomGeometry(scene: scene, config: parent.roomConfig, wallColor: parent.wallColor) }
        func createRoomGeometry(scene: SCNScene, config: EditableRoom) { createRoomGeometry(scene: scene, config: config, wallColor: parent.wallColor) }
        
        func createRoomGeometry(scene: SCNScene, config: EditableRoom, wallColor: UIColor) {
            floorNode?.removeFromParentNode(); frontWallNode?.removeFromParentNode(); backWallNode?.removeFromParentNode(); leftWallNode?.removeFromParentNode(); rightWallNode?.removeFromParentNode()
            
            let w = CGFloat(config.width); let l = CGFloat(config.length); let h = CGFloat(config.height)
            
            // FLOOR (Neutral Gray to show shadows well)
            let floorGeo = SCNBox(width: w, height: 0.1, length: l, chamferRadius: 0)
            let floorMat = SCNMaterial()
            floorMat.diffuse.contents = UIColor(white: 0.8, alpha: 1.0)
            floorMat.lightingModel = .phong
            floorGeo.materials = [floorMat]
            floorNode = SCNNode(geometry: floorGeo)
            floorNode?.position = SCNVector3(0,0,0); floorNode?.name = "floor"
            scene.rootNode.addChildNode(floorNode!)
            
            // WALLS (Glowing for Visibility)
            let wallMat = SCNMaterial()
            wallMat.diffuse.contents = wallColor
            wallMat.lightingModel = .phong
            wallMat.emission.contents = wallColor
            wallMat.emission.intensity = 0.05 
            wallMat.isDoubleSided = true
            wallMat.transparencyMode = .aOne
            wallMat.writesToDepthBuffer = true
            
            // Ghost Walls (No shadows cast)
            frontWallNode = createWallNode(w: w, h: h, l: 0.1, pos: SCNVector3(0, h/2, l/2), mat: wallMat, name: "frontWall")
            frontWallNode?.castsShadow = false
            backWallNode = createWallNode(w: w, h: h, l: 0.1, pos: SCNVector3(0, h/2, -l/2), mat: wallMat, name: "backWall")
            backWallNode?.castsShadow = false
            leftWallNode = createWallNode(w: 0.1, h: h, l: l, pos: SCNVector3(-w/2, h/2, 0), mat: wallMat, name: "leftWall")
            leftWallNode?.castsShadow = false
            rightWallNode = createWallNode(w: 0.1, h: h, l: l, pos: SCNVector3(w/2, h/2, 0), mat: wallMat, name: "rightWall")
            rightWallNode?.castsShadow = false
            
            scene.rootNode.addChildNode(frontWallNode!); scene.rootNode.addChildNode(backWallNode!)
            scene.rootNode.addChildNode(leftWallNode!); scene.rootNode.addChildNode(rightWallNode!)
        }
        
        private func createWallNode(w: CGFloat, h: CGFloat, l: CGFloat, pos: SCNVector3, mat: SCNMaterial, name: String) -> SCNNode {
            let geo = SCNBox(width: w, height: h, length: l, chamferRadius: 0)
            geo.materials = [mat.copy() as! SCNMaterial]
            let node = SCNNode(geometry: geo)
            node.position = pos; node.name = name
            return node
        }
        
        func updateWallColor(scene: SCNScene, color: UIColor) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            let walls = [frontWallNode, backWallNode, leftWallNode, rightWallNode]
            for wall in walls {
                guard let mat = wall?.geometry?.materials.first else { continue }
                mat.diffuse.contents = color
                mat.emission.contents = color
            }
            SCNTransaction.commit()
        }
        
        func updateRoomSize(scene: SCNScene, config: EditableRoom) { createRoomGeometry(scene: scene, config: config, wallColor: parent.wallColor) }
        
        func setupCamera(scene: SCNScene) {
            cameraPivot = SCNNode(); cameraPivot?.position = SCNVector3(0, 1.5, 0)
            cameraOrbit = SCNNode(); cameraNode = SCNNode(); cameraNode?.camera = SCNCamera(); cameraNode?.camera?.zFar = 100; cameraNode?.camera?.fieldOfView = 60
            
            let camLight = SCNLight(); camLight.type = .omni; camLight.intensity = 200; camLight.color = UIColor(white: 0.8, alpha: 1.0); camLight.castsShadow = false
            cameraNode?.light = camLight
            
            scene.rootNode.addChildNode(cameraPivot!); cameraPivot?.addChildNode(cameraOrbit!); cameraOrbit?.addChildNode(cameraNode!)
            
            firstPersonCamera = SCNNode(); firstPersonCamera?.camera = SCNCamera(); firstPersonCamera?.position = SCNVector3(0, 1.6, 0)
            scene.rootNode.addChildNode(firstPersonCamera!)
            updateCameraPosition(); sceneView?.pointOfView = cameraNode
        }
        
        func updateWallTransparency(scene: SCNScene) {
            var angle = Int(cameraAngleY) % 360; if angle < 0 { angle += 360 }
            frontWallNode?.isHidden = false; backWallNode?.isHidden = false; leftWallNode?.isHidden = false; rightWallNode?.isHidden = false
            if isFirstPersonMode { return }
            if angle > 300 || angle < 60 { frontWallNode?.isHidden = true }
            if angle > 30 && angle < 150 { rightWallNode?.isHidden = true }
            if angle > 120 && angle < 240 { backWallNode?.isHidden = true }
            if angle > 210 && angle < 330 { leftWallNode?.isHidden = true }
        }
        
        func updateCameraPosition() {
            cameraNode?.position = SCNVector3(0, 0, cameraDistance)
            cameraOrbit?.eulerAngles = SCNVector3(cameraAngleX * .pi / 180.0, cameraAngleY * .pi / 180.0, 0)
        }
        
        func switchToFirstPersonView() { firstPersonAngleX = 0; firstPersonAngleY = 0; firstPersonCamera?.eulerAngles = SCNVector3Zero; sceneView?.pointOfView = firstPersonCamera }
        func switchToOrbitView() { updateCameraPosition(); sceneView?.pointOfView = cameraNode; if let s = sceneView?.scene { updateWallTransparency(scene: s) } }
        
        func updateFurnitureNodes(scene: SCNScene, nodes: [FurnitureNode]) {
            let existing = scene.rootNode.childNodes.compactMap { $0 as? FurnitureNode }
            
            for node in nodes where !existing.contains(where: { $0.furnitureItem.id == node.furnitureItem.id }) {
                node.setupGeometryIfNeeded()
                
                // --- ADD THIS LINE ---
                applyMaterialFix(to: node)
                // ---------------------
                
                scene.rootNode.addChildNode(node)
            }
            
            for old in existing where !nodes.contains(where: { $0.furnitureItem.id == old.furnitureItem.id }) {
                old.removeFromParentNode()
            }
        }
        private func applyMaterialFix(to node: SCNNode) {
            node.enumerateChildNodes { (child, _) in
                guard let geometry = child.geometry else { return }
                
                for material in geometry.materials {
                    // 1. Force Physically Based Rendering (Best for realism)
                    material.lightingModel = .physicallyBased
                    
                    // 2. Kill any "Glow" (Emission)
                    // Some models import with a white emission setting by mistake
                    material.emission.contents = UIColor.black
                    
                    // 3. Reset Ambient
                    // Ensure the object doesn't have "internal light"
                    material.ambient.contents = UIColor.black
                    
                    // 4. The "Sunglasses" Trick (Multiply)
                    // This darkens the existing texture/color by 15% without deleting it.
                    // It turns "Blinding White" into "Realistic White".
                    material.multiply.contents = UIColor(white: 0.85, alpha: 1.0)
                    
                    // 5. Soften Highlights
                    // High roughness prevents mirror-like reflections on the white paint
                    material.roughness.contents = 0.6
                }
            }
        }
        
        func setupGestures(sceneView: SCNView) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            let twoPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
            twoPan.minimumNumberOfTouches = 2
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            sceneView.addGestureRecognizer(tap); sceneView.addGestureRecognizer(pan); sceneView.addGestureRecognizer(twoPan); sceneView.addGestureRecognizer(pinch)
        }
        
        // MARK: - Highlight Selection (Cyan + Transparent)
        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let v = g.view as? SCNView else { return }
            let hit = v.hitTest(g.location(in: v)).first; var node = hit?.node
            
            if let previousSelection = parent.selectedNode {
                removeSelectionHighlight(from: previousSelection)
                removeDimensionLabel(from: previousSelection)
            }
            
            while node != nil && !(node is FurnitureNode) { node = node?.parent }
            
            if let furniture = node as? FurnitureNode {
                parent.selectedNode = furniture
                addSelectionHighlight(to: furniture)
                addDimensionLabel(to: furniture)
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
                        newMaterial.emission.contents = UIColor.cyan
                        newMaterial.emission.intensity = 0.4
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
        
        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            let t = g.translation(in: g.view)
            if isEditing, let sel = parent.selectedNode, let scene = sceneView?.scene {
                let scale: Float = 0.01
                if editMode == .move {
                    let newPos = SCNVector3(sel.position.x + Float(t.x)*scale, sel.position.y, sel.position.z - Float(t.y)*scale)
                    let clamped = applyCollisionDetection(position: newPos, furniture: sel, scene: scene)
                    sel.position = clamped; if g.state == .ended { parent.onFurnitureMoved(sel.furnitureItem, clamped) }
                } else if editMode == .rotate {
                    sel.eulerAngles.y -= Float(t.x) * scale; if g.state == .ended { parent.onFurnitureRotated(sel.furnitureItem, sel.eulerAngles) }
                } else if editMode == .scale {
                    let s = max(0.5, min(3.0, sel.scale.x - Float(t.y)*scale))
                    sel.scale = SCNVector3(s,s,s); if g.state == .ended { parent.onFurnitureScaled(sel.furnitureItem, sel.scale) }
                }
                g.setTranslation(.zero, in: g.view)
            } else if isFirstPersonMode {
                firstPersonAngleY -= Float(t.x) * 0.005; firstPersonAngleX -= Float(t.y) * 0.005
                firstPersonCamera?.eulerAngles = SCNVector3(firstPersonAngleX, firstPersonAngleY, 0); g.setTranslation(.zero, in: g.view)
            } else {
                cameraAngleY -= Float(t.x) * 0.5; cameraAngleX -= Float(t.y) * 0.5; updateCameraPosition(); g.setTranslation(.zero, in: g.view)
                if let s = sceneView?.scene { updateWallTransparency(scene: s) }
            }
        }
        
        private func applyCollisionDetection(position: SCNVector3, furniture: FurnitureNode, scene: SCNScene) -> SCNVector3 {
            let config = parent.roomConfig; let w = config.width; let l = config.length
            let fw = Float(furniture.catalogItem?.defaultDimensions.width ?? 1.0) / 2.0
            let fd = Float(furniture.catalogItem?.defaultDimensions.depth ?? 1.0) / 2.0
            var pos = position
            pos.x = max(-w/2 + fw + 0.05, min(w/2 - fw - 0.05, pos.x))
            pos.z = max(-l/2 + fd + 0.05, min(l/2 - fd - 0.05, pos.z))
            pos.y = 0; return pos
        }
        
        @objc func handleTwoFingerPan(_ g: UIPanGestureRecognizer) {
            guard !isFirstPersonMode, let pivot = cameraPivot else { return }
            let t = g.translation(in: g.view); pivot.position.x -= Float(t.x) * 0.01; pivot.position.z += Float(t.y) * 0.01; g.setTranslation(.zero, in: g.view)
            if let s = sceneView?.scene { updateWallTransparency(scene: s) }
        }
        
        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            if !isFirstPersonMode { cameraDistance /= Float(g.scale); updateCameraPosition(); g.scale = 1.0 }
        }
        
        func addDimensionLabel(to furniture: FurnitureNode) {
            removeDimensionLabel(from: furniture)
            let (min, max) = furniture.boundingBox; let w = (max.x - min.x) * furniture.scale.x; let h = (max.y - min.y) * furniture.scale.y; let d = (max.z - min.z) * furniture.scale.z
            let text = SCNText(string: String(format: "%.2fm × %.2fm × %.2fm", w, h, d), extrusionDepth: 0.01)
            text.font = UIFont(name: "Helvetica-Bold", size: 18); text.flatness = 0.1
            text.materials = [SCNMaterial(), SCNMaterial()]; text.materials[0].diffuse.contents = UIColor.black; text.materials[1].diffuse.contents = UIColor.black.withAlphaComponent(0.8)
            let node = SCNNode(geometry: text); node.name = dimensionLabelName; node.scale = SCNVector3(0.004, 0.004, 0.004)
            let bounds = text.boundingBox; node.pivot = SCNMatrix4MakeTranslation((bounds.max.x - bounds.min.x)/2, 0, 0)
            node.position = SCNVector3(0, max.y * furniture.scale.y + 0.15, 0)
            let constraint = SCNBillboardConstraint(); constraint.freeAxes = .Y; node.constraints = [constraint]
            furniture.addChildNode(node)
        }

        func removeDimensionLabel(from furniture: FurnitureNode) { furniture.childNode(withName: dimensionLabelName, recursively: false)?.removeFromParentNode() }
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