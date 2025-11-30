import SwiftUI

@main
struct HomiApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var layoutManager = LayoutManager()
    
    init() {
        // Log bundle contents for debugging USDZ asset issues
        debugBundleContents()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(layoutManager)
        }
    }
    
    /// Root routing view based on authentication state.
    private struct RootView: View {
        @EnvironmentObject var authManager: AuthManager
        @EnvironmentObject var layoutManager: LayoutManager
        
        var body: some View {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    AuthenticationView()
                }
            }
            .animation(.easeInOut, value: authManager.isAuthenticated)
        }
    }
    
    /// Prints bundle contents on launch to verify USDZ assets are included.
    private func debugBundleContents() {
        print("\n" + String(repeating: "=", count: 60))
        print("HOMI APP LAUNCHED")
        print(String(repeating: "=", count: 60))
        
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Failed to locate bundle resource path.")
            print(String(repeating: "=", count: 60) + "\n")
            return
        }
        
        print("Bundle path: \(resourcePath)")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
            let usdzFiles = contents.filter { $0.hasSuffix(".usdz") }
            
            print("\nTotal files: \(contents.count)")
            print("USDZ files: \(usdzFiles.count)")
            
            if usdzFiles.isEmpty {
                print("No USDZ files found. Check Target Membership.")
            } else {
                print("USDZ Files:")
                for file in usdzFiles {
                    print(" • \(file)")
                    
                    let fullPath = (resourcePath as NSString).appendingPathComponent(file)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                       let size = attrs[.size] as? Int64 {
                        let sizeKB = Double(size) / 1024.0
                        print("   Size: \(String(format: "%.1f", sizeKB)) KB")
                    }
                }
            }
            
        } catch {
            print("Failed to read bundle contents: \(error)")
        }
        
        print(String(repeating: "=", count: 60) + "\n")
    }
}