import SwiftUI

@main
struct HomiApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var layoutManager = LayoutManager()
    
    init() {
        // Force debug output on app launch
        debugBundleContents()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(layoutManager)
        }
    }
    
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
    
    private func debugBundleContents() {
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 HOMI APP LAUNCHED")
        print(String(repeating: "=", count: 60))
        
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Bundle path: \(resourcePath)")
            
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
