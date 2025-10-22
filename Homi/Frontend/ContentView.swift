import SwiftUI

struct ContentView: View {
    @StateObject private var layoutManager = LayoutManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main 3D Room View
            RoomView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Room")
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
            SavedLayoutsView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Layouts")
                }
                .tag(2)
        }
        .environmentObject(layoutManager)
    }
}

struct SavedLayoutsView: View {
    @EnvironmentObject var layoutManager: LayoutManager
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
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Retry") {
                            loadLayouts()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if layouts.isEmpty {
                    VStack {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No saved layouts")
                            .foregroundColor(.gray)
                        Text("Create your first room layout in the Room tab")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(layouts) { layout in
                        LayoutRowView(layout: layout)
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
    @EnvironmentObject var layoutManager: LayoutManager
    
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
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete") {
                    Task {
                        try? await APIService.shared.deleteLayout(id: layout.id)
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
