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
                                    CatalogItemCard(item: item)
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
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Furniture Image
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 140)
                            ProgressView()
                        }
                        .cornerRadius(12)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: .infinity, height: 140)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        FallbackIcon(type: item.type)
                    @unknown default:
                        FallbackIcon(type: item.type)
                    }
                }
                .frame(height: 140)
            } else {
                FallbackIcon(type: item.type)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                Text(item.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", item.defaultDimensions.width))m × \(String(format: "%.1f", item.defaultDimensions.depth))m × \(String(format: "%.1f", item.defaultDimensions.height))m")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let description = item.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct FallbackIcon: View {
    let type: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(height: 140)
            .overlay(
                VStack {
                    Image(systemName: furnitureIcon(for: type))
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(type)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
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

#Preview {
    CatalogView()
        .environmentObject(LayoutManager())
}