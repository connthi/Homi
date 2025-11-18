import SwiftUI

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

// MARK: - Main Menu View

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
                    // Reset layout manager for a fresh start
                    layoutManager.createNewLayout(name: "New Room \(Date().formatted(date: .abbreviated, time: .omitted))")
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
        .navigationBarHidden(true) // Hide default nav bar for custom header look
        .onAppear {
            loadRecentLayouts()
        }
    }
    
    // Helper to fetch layouts for the carousel
    private func loadRecentLayouts() {
        isLoadingRecents = true
        Task {
            do {
                // We fetch all, but we will sort and take the top 5
                let allLayouts = try await APIService.shared.fetchLayouts()
                await MainActor.run {
                    // Sort by creation date (newest first) and take top 5
                    self.recentLayouts = allLayouts
                        .sorted(by: { $0.createdAt > $1.createdAt })
                        .prefix(5)
                        .map { $0 } // Convert ArraySlice back to Array
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
                // Placeholder visual for the room
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
        // Subtle border instead of shadow for a cleaner look
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

// MARK: - Layout Row

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
        .environmentObject(AuthManager())
        .environmentObject(LayoutManager())
}
