import SwiftUI
import SceneKit
import Photos

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var layoutManager = LayoutManager()
    
    @State private var selectedTab = 0
    @State private var showingRoomView = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // HOME
            NavigationStack {
                MainMenuView(showingRoomView: $showingRoomView)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // CATALOG
            NavigationStack {
                CatalogView()
            }
            .tabItem {
                Image(systemName: "sofa.fill")
                Text("Catalog")
            }
            .tag(1)
            
            // SAVED LAYOUTS
            NavigationStack {
                SavedLayoutsView(showingRoomView: $showingRoomView)
            }
            .tabItem {
                Image(systemName: "folder.fill")
                Text("Layouts")
            }
            .tag(2)
        }
        .environmentObject(layoutManager)
        .fullScreenCover(isPresented: $showingRoomView) {
            RoomView()
                .environmentObject(layoutManager)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Main Menu View (Dashboard Style)

struct MainMenuView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var layoutManager: LayoutManager
    @Binding var showingRoomView: Bool
    
    // Local state for the dashboard
    @State private var recentLayouts: [Layout] = []
    @State private var isLoadingRecents = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. HEADER SECTION
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome Home")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Ready to design?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Profile / Logout Button
                    Menu {
                        Button(role: .destructive) {
                            Task { await authManager.logout() }
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // 2. HERO SECTION (Start New)
                Button(action: {
                    layoutManager.currentLayout = nil
                    layoutManager.furnitureNodes = []
                    showingRoomView = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Project")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Start from scratch")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                
                // 3. RECENT PROJECTS (Horizontal Scroll)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Jump Back In")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoadingRecents {
                        ProgressView()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                    } else if recentLayouts.isEmpty {
                        // Empty State for Recents
                        VStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No recent designs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recentLayouts) { layout in
                                    RecentProjectCard(layout: layout) {
                                        // Action: Load this layout and open room view
                                        layoutManager.loadLayout(layout)
                                        showingRoomView = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // 4. INSPIRATION / TOOLS (Grid)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get Inspired")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Static cards for visual appeal
                        InspirationCard(title: "Modern Living", icon: "sofa.fill", color: .orange)
                        InspirationCard(title: "Minimalist", icon: "square.split.bottomrightquarter", color: .teal)
                        InspirationCard(title: "Office", icon: "desktopcomputer", color: .indigo)
                        InspirationCard(title: "Cozy Bedroom", icon: "bed.double.fill", color: .pink)
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadRecentLayouts()
        }
    }
    
    private func loadRecentLayouts() {
        isLoadingRecents = true
        Task {
            do {
                let allLayouts = try await APIService.shared.fetchLayouts()
                await MainActor.run {
                    self.recentLayouts = allLayouts
                        .sorted(by: { $0.createdAt > $1.createdAt })
                        .prefix(5)
                        .map { $0 }
                    self.isLoadingRecents = false
                }
            } catch {
                print("Failed to fetch recents: \(error)")
                await MainActor.run { isLoadingRecents = false }
            }
        }
    }
}

// MARK: - Subcomponents for Dashboard

struct RecentProjectCard: View {
    let layout: Layout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                    Image(systemName: "cube.transparent")
                        .foregroundColor(.blue.opacity(0.3))
                        .font(.largeTitle)
                }
                .frame(height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layout.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(layout.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
            }
            .background(Color(.systemBackground))
            .frame(width: 140, height: 140)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct InspirationCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18))
                )
            
            Spacer()
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Saved Layouts View

struct SavedLayoutsView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @Binding var showingRoomView: Bool
    @State private var layouts: [Layout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading layouts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error Loading Layouts")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .font(.caption)
                        Button("Retry") {
                            loadLayouts()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if layouts.isEmpty {
                VStack {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No saved layouts")
                        .foregroundColor(.gray)
                    Text("Create your first room layout in the Home tab")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(layouts) { layout in
                        LayoutRowView(layout: layout, showingRoomView: $showingRoomView) {
                            loadLayouts()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Saved Layouts")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadLayoutsAsync()
        }
        .onAppear {
            loadLayouts()
        }
    }
    
    private func loadLayouts() {
        Task {
            await loadLayoutsAsync()
        }
    }
    
    private func loadLayoutsAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedLayouts = try await APIService.shared.fetchLayouts()
            await MainActor.run {
                self.layouts = fetchedLayouts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Layout Row with Export Button

struct LayoutRowView: View {
    let layout: Layout
    @Binding var showingRoomView: Bool
    let onRefresh: () -> Void
    @EnvironmentObject var layoutManager: LayoutManager
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showExportSuccess = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(layout.name)
                        .font(.headline)
                    Spacer()
                    Text(layout.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(layout.furnitureItems.count) furniture items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Button("Load") {
                        layoutManager.loadLayout(layout)
                        showingRoomView = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDeleting)
                    
                    Button("Export") {
                        exportLayout()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDeleting)
                    
                    Spacer()
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(isDeleting)
                }
            }
            .padding(.vertical, 4)
            .opacity(isDeleting ? 0.5 : 1.0)
            .alert("Delete Layout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteLayout()
                }
            } message: {
                Text("Are you sure you want to delete '\(layout.name)'? This action cannot be undone.")
            }
            
            // Export Success Toast
            if showExportSuccess {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "photo.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved to Photos!")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    private func exportLayout() {
        // Create a temporary scene to export
        let scene = SCNScene()
        
        // Setup room
        let roomConfig = EditableRoom.default
        let wallColor = layoutManager.wallColor
        
        // Create room geometry
        let roomWidth = CGFloat(roomConfig.width)
        let roomLength = CGFloat(roomConfig.length)
        let roomHeight = CGFloat(roomConfig.height)
        
        // Floor
        let floorGeometry = SCNBox(width: roomWidth, height: 0.1, length: roomLength, chamferRadius: 0)
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        floorGeometry.materials = [floorMaterial]
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(floorNode)
        
        // Walls
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = wallColor
        
        let backWall = SCNBox(width: roomWidth, height: roomHeight, length: 0.1, chamferRadius: 0)
        backWall.materials = [wallMaterial.copy() as! SCNMaterial]
        let backWallNode = SCNNode(geometry: backWall)
        backWallNode.position = SCNVector3(0, roomHeight/2, -roomLength/2)
        backWallNode.name = "backWall"
        scene.rootNode.addChildNode(backWallNode)
        
        let leftWall = SCNBox(width: 0.1, height: roomHeight, length: roomLength, chamferRadius: 0)
        leftWall.materials = [wallMaterial.copy() as! SCNMaterial]
        let leftWallNode = SCNNode(geometry: leftWall)
        leftWallNode.position = SCNVector3(-roomWidth/2, roomHeight/2, 0)
        leftWallNode.name = "leftWall"
        scene.rootNode.addChildNode(leftWallNode)
        
        // Add furniture
        let furnitureNodes = layout.furnitureItems.map { furnitureItem -> FurnitureNode in
            let catalogItem = layoutManager.catalogItems.first { $0.id == furnitureItem.furnitureId }
            return FurnitureNode(furnitureItem: furnitureItem, catalogItem: catalogItem)
        }
        
        for node in furnitureNodes {
            node.setupGeometryIfNeeded()
            scene.rootNode.addChildNode(node)
        }
        
        // Add lighting
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
        let mainLightNode = SCNNode()
        mainLightNode.light = mainLight
        mainLightNode.position = SCNVector3(5, 10, 5)
        mainLightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(mainLightNode)
        
        // Export
        ImageExporter.shared.exportRoomLayout(
            scene: scene,
            furnitureNodes: furnitureNodes,
            roomConfig: roomConfig,
            wallColor: wallColor
        ) { result in
            switch result {
            case .success:
                withAnimation {
                    showExportSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showExportSuccess = false
                    }
                }
            case .failure(let error):
                exportErrorMessage = error.localizedDescription
                showExportError = true
            }
        }
    }
    
    private func deleteLayout() {
        isDeleting = true
        Task {
            guard let id = layout.id else {
                print("❌ No layout ID found – cannot delete unsaved layout.")
                isDeleting = false
                return
            }

            do {
                try await APIService.shared.deleteLayout(id: id)
                await MainActor.run {
                    onRefresh()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    print("Failed to delete layout: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(LayoutManager())
}