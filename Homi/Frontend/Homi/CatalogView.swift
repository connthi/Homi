import SwiftUI

struct CatalogView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @State private var catalogItems: [CatalogItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Sofa", "Chair", "Table", "Bed", "Storage", "Lighting"]
    
    var filteredItems: [CatalogItem] {
        let categoryFiltered = selectedCategory == "All" ? catalogItems : catalogItems.filter { $0.type == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading catalog...")
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
                            loadCatalog()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Search Bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryButton(
                                        title: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Catalog Grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredItems) { item in
                                    CatalogItemCard(item: item) {
                                        addToRoom(item)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Furniture Catalog")
            .refreshable {
                await loadCatalogAsync()
            }
            .onAppear {
                if !layoutManager.isCatalogLoaded {
                    loadCatalog()
                } else {
                    catalogItems = layoutManager.catalogItems
                }
            }
        }
    }
    
    private func loadCatalog() {
        Task {
            await loadCatalogAsync()
        }
    }
    
    private func loadCatalogAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let items = try await APIService.shared.fetchCatalog()
            await MainActor.run {
                self.catalogItems = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func addToRoom(_ item: CatalogItem) {
        // In a real implementation, this would open the room view and allow placement
        // For now, we'll just show a confirmation
        print("Adding \(item.name) to room")
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search furniture...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryButton: View {
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

struct CatalogItemCard: View {
    let item: CatalogItem
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Furniture Preview (placeholder)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: furnitureIcon(for: item.type))
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(item.type)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(item.defaultDimensions.width))×\(Int(item.defaultDimensions.depth))×\(Int(item.defaultDimensions.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !item.materialOptions.isEmpty {
                    Text("Materials: \(item.materialOptions.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button("Add to Room") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func furnitureIcon(for type: String) -> String {
        switch type.lowercased() {
        case "sofa":
            return "sofa.fill"
        case "chair":
            return "chair.fill"
        case "table":
            return "table.furniture.fill"
        case "bed":
            return "bed.double.fill"
        case "storage":
            return "cabinet.fill"
        case "lighting":
            return "lightbulb.fill"
        default:
            return "cube.fill"
        }
    }
}

#Preview {
    CatalogView()
        .environmentObject(LayoutManager())
}
