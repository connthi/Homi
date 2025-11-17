import SwiftUI

// MARK: - New Layout Dialog with Wall Color Selection
struct NewLayoutDialog: View {
    @Binding var layoutName: String
    @Binding var isPresented: Bool
    let onCreate: (String, UIColor) -> Void
    
    @State private var selectedWallColor: Color = Color(UIColor(white: 0.95, alpha: 1.0))
    
    // Predefined wall color options
    private let wallColorOptions: [(name: String, color: Color)] = [
        ("White", Color(UIColor(white: 0.95, alpha: 1.0))),
        ("Beige", Color(red: 0.96, green: 0.96, blue: 0.86)),
        ("Light Gray", Color(UIColor(white: 0.85, alpha: 1.0))),
        ("Cream", Color(red: 1.0, green: 0.99, blue: 0.94)),
        ("Pale Blue", Color(red: 0.88, green: 0.94, blue: 0.98)),
        ("Light Green", Color(red: 0.92, green: 0.98, blue: 0.92)),
        ("Soft Pink", Color(red: 0.98, green: 0.92, blue: 0.94)),
        ("Light Yellow", Color(red: 0.99, green: 0.98, blue: 0.88))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Create New Layout")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Give your room design a name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Layout Name", text: $layoutName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 32)
                        .submitLabel(.done)
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    // Wall Color Selection
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.blue)
                            Text("Choose Wall Color")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal, 32)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(wallColorOptions, id: \.name) { option in
                                WallColorOption(
                                    name: option.name,
                                    color: option.color,
                                    isSelected: selectedWallColor == option.color
                                ) {
                                    selectedWallColor = option.color
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button("Create") {
                            if !layoutName.trimmingCharacters(in: .whitespaces).isEmpty {
                                onCreate(layoutName, UIColor(selectedWallColor))
                                isPresented = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(layoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Set default name with timestamp
            if layoutName.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                layoutName = "Room \(formatter.string(from: Date()))"
            }
        }
    }
}

// MARK: - Wall Color Option Button
struct WallColorOption: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                            )
                    }
                }
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewLayoutDialog(
        layoutName: .constant(""),
        isPresented: .constant(true),
        onCreate: { _, _ in }
    )
}