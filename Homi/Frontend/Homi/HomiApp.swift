import SwiftUI

@main
struct HomiApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var layoutManager = LayoutManager()
    @State private var sharedLayoutId: String?
    
    init() {
        debugBundleContents()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(sharedLayoutId: $sharedLayoutId)
                .environmentObject(authManager)
                .environmentObject(layoutManager)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }
    
    private struct RootView: View {
        @EnvironmentObject var authManager: AuthManager
        @EnvironmentObject var layoutManager: LayoutManager
        @Binding var sharedLayoutId: String?
        @State private var showSharedRoom = false
        
        var body: some View {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    AuthenticationView()
                }
            }
            .animation(.easeInOut, value: authManager.isAuthenticated)
            .fullScreenCover(isPresented: $showSharedRoom) {
                if sharedLayoutId != nil {
                    SharedRoomView(shareId: sharedLayoutId!, onDismiss: {
                        sharedLayoutId = nil
                        showSharedRoom = false
                    })
                    .environmentObject(layoutManager)
                }
            }
            .onChange(of: sharedLayoutId) { oldValue, newValue in
                if newValue != nil {
                    showSharedRoom = true
                }
            }
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(url: URL) {
        print("🔗 Deep link received: \(url)")
        
        // Handle URLs like:
        // homi://view/ABC123
        // https://homi.app/view/ABC123
        
        let pathComponents = url.pathComponents
        
        // Check if it's a view link
        if pathComponents.count >= 2 {
            // pathComponents = ["/", "view", "ABC123"]
            if let viewIndex = pathComponents.firstIndex(of: "view"),
               viewIndex + 1 < pathComponents.count {
                let shareId = pathComponents[viewIndex + 1]
                print("✅ Extracted share ID: \(shareId)")
                sharedLayoutId = shareId
                return
            }
        }
        
        // Also handle query parameters: ?share=ABC123
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let shareParam = queryItems.first(where: { $0.name == "share" }),
           let shareId = shareParam.value {
            print("✅ Extracted share ID from query: \(shareId)")
            sharedLayoutId = shareId
            return
        }
        
        print("⚠️ Could not parse share ID from URL")
    }
    
    private func debugBundleContents() {
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 HOMI APP LAUNCHED")
        print(String(repeating: "=", count: 60))
        
        if let resourcePath = Bundle.main.resourcePath {
            print("📂 Bundle path: \(resourcePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let usdzFiles = contents.filter { $0.hasSuffix(".usdz") }
                
                print("\n📦 Total files in bundle: \(contents.count)")
                print("🎯 USDZ files found: \(usdzFiles.count)")
                
                if usdzFiles.isEmpty {
                    print("❌ NO USDZ FILES IN BUNDLE!")
                    print("⚠️  This means Target Membership is not set correctly")
                } else {
                    print("✅ USDZ Files:")
                    for file in usdzFiles {
                        print("   • \(file)")
                        
                        let fullPath = (resourcePath as NSString).appendingPathComponent(file)
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                           let size = attrs[.size] as? Int64 {
                            let sizeKB = Double(size) / 1024.0
                            print("     Size: \(String(format: "%.1f", sizeKB)) KB")
                        }
                    }
                }
                
            } catch {
                print("❌ Error reading bundle: \(error)")
            }
        } else {
            print("❌ Could not get resource path!")
        }
        
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// MARK: - Shared Room View Wrapper

struct SharedRoomView: View {
    @EnvironmentObject var layoutManager: LayoutManager
    let shareId: String
    let onDismiss: () -> Void
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading shared room...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Failed to load room")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Close") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                RoomView(isViewOnly: true)
                    .environmentObject(layoutManager)
            }
        }
        .task {
            await loadSharedLayout()
        }
    }
    
    private func loadSharedLayout() async {
        do {
            try await layoutManager.loadSharedLayout(shareId: shareId)
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}