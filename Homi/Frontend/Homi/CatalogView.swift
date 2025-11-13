import SwiftUI

struct CatalogView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @State private var catalogItems: [CatalogItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingWallpaperPicker = false
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingWallpaperPicker = true
                    }) {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
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
            .sheet(isPresented: $showingWallpaperPicker) {
                WallpaperPickerView()
                    .environmentObject(layoutManager)
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

// MARK: - Wallpaper Picker View

// Helper function to compare UIColor values
private func colorsAreEqual(_ color1: UIColor, _ color2: UIColor) -> Bool {
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
    
    // Try to get RGB values, fallback to grayscale if needed
    if color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) &&
       color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) {
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 && abs(a1 - a2) < 0.01
    } else {
        // Fallback for grayscale colors
        var w1: CGFloat = 0, a1: CGFloat = 0
        var w2: CGFloat = 0, a2: CGFloat = 0
        color1.getWhite(&w1, alpha: &a1)
        color2.getWhite(&w2, alpha: &a2)
        return abs(w1 - w2) < 0.01 && abs(a1 - a2) < 0.01
    }
}

struct WallpaperPickerView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    @Environment(\.dismiss) var dismiss
    
    // Predefined color options
    let colorOptions: [(name: String, color: UIColor)] = [
        ("White", UIColor(white: 0.95, alpha: 1.0)),
        ("Cream", UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)),
        ("Light Gray", UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)),
        ("Beige", UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0)),
        ("Light Blue", UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1.0)),
        ("Light Green", UIColor(red: 0.88, green: 0.95, blue: 0.88, alpha: 1.0)),
        ("Lavender", UIColor(red: 0.92, green: 0.88, blue: 0.95, alpha: 1.0)),
        ("Peach", UIColor(red: 0.98, green: 0.90, blue: 0.85, alpha: 1.0)),
        ("Mint", UIColor(red: 0.85, green: 0.98, blue: 0.92, alpha: 1.0)),
        ("Pale Yellow", UIColor(red: 0.98, green: 0.98, blue: 0.85, alpha: 1.0)),
        ("Light Pink", UIColor(red: 0.98, green: 0.90, blue: 0.92, alpha: 1.0)),
        ("Sky Blue", UIColor(red: 0.80, green: 0.92, blue: 0.98, alpha: 1.0))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose Wall Color")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Select a color to apply to all walls in your room")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(colorOptions, id: \.name) { option in
                            ColorOptionCard(
                                name: option.name,
                                color: Color(option.color),
                                isSelected: colorsAreEqual(layoutManager.wallColor, option.color),
                                onSelect: {
                                    layoutManager.wallColor = option.color
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Wallpaper")
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

struct ColorOptionCard: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Circle().fill(Color.white))
                    )
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CatalogView()
        .environmentObject(LayoutManager())
}