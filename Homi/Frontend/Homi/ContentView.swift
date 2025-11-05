import SwiftUI

struct ContentView: View {
    @StateObject private var layoutManager = LayoutManager()
    @State private var selectedTab = 0
    @State private var showingRoomView = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Menu / Home
            MainMenuView(showingRoomView: $showingRoomView)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Furniture Catalog
            CatalogView()
                .tabItem {
                    Image(systemName: "sofa.fill")
                    Text("Catalog")
                }
                .tag(1)
            
            // Saved Layouts
            SavedLayoutsView(showingRoomView: $showingRoomView)
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
        }
    }
}

// MARK: - Main Menu View

struct MainMenuView: View {
    @Binding var showingRoomView: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Homi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Design your perfect space")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingRoomView = true
                    }) {
                        Label("Start New Design", systemImage: "plus.circle.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Load a saved layout from the Layouts tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

struct SavedLayoutsView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @Binding var showingRoomView: Bool
    @State private var layouts: [Layout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
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
                }
            }
            .navigationTitle("Saved Layouts")
            .refreshable {
                await loadLayoutsAsync()
            }
            .onAppear {
                loadLayouts()
            }
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

struct LayoutRowView: View {
    let layout: Layout
    @Binding var showingRoomView: Bool
    let onRefresh: () -> Void
    @EnvironmentObject var layoutManager: LayoutManager
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
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
            
            HStack {
                Button("Load") {
                    layoutManager.loadLayout(layout)
                    showingRoomView = true
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
    }
    
    private func deleteLayout() {
        isDeleting = true
        Task {
            guard let id = layout.id else {
                print("❌ No layout ID found — cannot delete unsaved layout.")
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
}