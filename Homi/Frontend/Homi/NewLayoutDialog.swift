import SwiftUI

// MARK: - New Layout Dialog
// This dialog appears when the user wants to create a new room layout.
// It prompts for a layout name and handles the creation flow.
struct NewLayoutDialog: View {
    @Binding var layoutName: String
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
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
                    .onSubmit {
                        if !layoutName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onCreate(layoutName)
                            isPresented = false
                        }
                    }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Create") {
                        if !layoutName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onCreate(layoutName)
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(layoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 32)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            // Set default name with timestamp (e.g., "Room Nov 9, 2:30 PM")
            if layoutName.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                layoutName = "Room \(formatter.string(from: Date()))"
            }
        }
    }
}

#Preview {
    NewLayoutDialog(
        layoutName: .constant(""),
        isPresented: .constant(true),
        onCreate: { _ in }
    )
}
