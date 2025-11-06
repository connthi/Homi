import Foundation
import SceneKit

// MARK: - Data Models matching backend API

struct Layout: Codable, Identifiable {
    var id: String?
    let userId: String
    let name: String
    let createdAt: Date
    let furnitureItems: [FurnitureItem]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, name, createdAt, furnitureItems
    }
    
    init(id: String? = nil, userId: String, name: String, createdAt: Date, furnitureItems: [FurnitureItem]) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.furnitureItems = furnitureItems
    }
}

struct FurnitureItem: Codable, Identifiable {
    var id: String
    let furnitureId: String
    let position: Position
    let rotation: Rotation
    let scale: Scale
    let properties: FurnitureProperties
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case furnitureId, position, rotation, scale, properties
    }

    init(
        id: String = UUID().uuidString,
        furnitureId: String,
        position: Position,
        rotation: Rotation,
        scale: Scale,
        properties: FurnitureProperties
    ) {
        self.id = id
        self.furnitureId = furnitureId
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.properties = properties
    }
}

struct Position: Codable {
    let x: Double
    let y: Double
    let z: Double
}

struct Rotation: Codable {
    let x: Double
    let y: Double
    let z: Double
}

struct Scale: Codable {
    let x: Double
    let y: Double
    let z: Double
}

struct FurnitureProperties: Codable {
    let color: String
    let material: String
}

struct CatalogItem: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let defaultDimensions: Dimensions
    let materialOptions: [String]
    let imageUrl: String?
    let description: String?
    let modelFileName: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, type, defaultDimensions, materialOptions, imageUrl, description, modelFileName
    }
}

struct Dimensions: Codable {
    let width: Double
    let height: Double
    let depth: Double
}

// MARK: - SceneKit Integration Models

class FurnitureNode: SCNNode {
    let furnitureItem: FurnitureItem
    let catalogItem: CatalogItem?
    
    init(furnitureItem: FurnitureItem, catalogItem: CatalogItem? = nil) {
        self.furnitureItem = furnitureItem
        self.catalogItem = catalogItem
        super.init()
        
        // Print all available bundle resources on first init
        var printedResources = false
        if !printedResources {
            printBundleResources()
            printedResources = true
        }
        
        setupGeometry()
        updateTransform()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func printBundleResources() {
        print("\n🔍 === BUNDLE RESOURCES DEBUG ===")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let usdzFiles = contents.filter { $0.hasSuffix(".usdz") }
                print("📦 Found \(usdzFiles.count) USDZ files in bundle:")
                for file in usdzFiles {
                    print("   ✅ \(file)")
                }
                if usdzFiles.isEmpty {
                    print("   ⚠️ NO USDZ FILES FOUND IN BUNDLE!")
                    print("   📁 Bundle path: \(resourcePath)")
                }
            } catch {
                print("   ❌ Error reading bundle: \(error)")
            }
        }
        print("=================================\n")
    }
    
    private func setupGeometry() {
        guard let modelFileName = catalogItem?.modelFileName, !modelFileName.isEmpty else {
            print("ℹ️ [\(catalogItem?.name ?? "Unknown")] No model filename, using basic geometry")
            createBasicGeometry()
            return
        }
        
        print("\n🔍 [\(catalogItem?.name ?? "Unknown")] Attempting to load: '\(modelFileName)'")
        
        // Try multiple variations of the filename
        let variations = [
            modelFileName,                           // As-is from database
            "\(modelFileName).usdz",                // Add .usdz
            modelFileName.replacingOccurrences(of: ".usdz", with: ""), // Remove .usdz if present
        ]
        
        var loaded = false
        for variant in variations {
            let cleanName = variant.replacingOccurrences(of: ".usdz", with: "")
            
            print("   🔎 Trying: '\(cleanName)' with extension 'usdz'")
            
            if let url = Bundle.main.url(forResource: cleanName, withExtension: "usdz") {
                print("   ✅ FOUND at: \(url.lastPathComponent)")
                if loadUSDZModel(from: url) {
                    print("   ✅ Successfully loaded 3D model!")
                    loaded = true
                    break
                } else {
                    print("   ❌ Failed to parse model file")
                }
            } else {
                print("   ❌ Not found in bundle")
            }
        }
        
        if !loaded {
            print("   ⚠️ ALL ATTEMPTS FAILED - Using basic geometry")
            createBasicGeometry()
        }
    }
    
    private func loadUSDZModel(from url: URL) -> Bool {
        do {
            let modelScene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .flattenScene: false
            ])
            
            // Calculate bounding box
            var minVec = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
            var maxVec = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
            var hasGeometry = false
            
            modelScene.rootNode.enumerateChildNodes { (node, _) in
                if node.geometry != nil {
                    hasGeometry = true
                    let (localMin, localMax) = node.boundingBox
                    let worldMin = node.convertPosition(localMin, to: nil)
                    let worldMax = node.convertPosition(localMax, to: nil)
                    
                    minVec.x = min(minVec.x, worldMin.x)
                    minVec.y = min(minVec.y, worldMin.y)
                    minVec.z = min(minVec.z, worldMin.z)
                    maxVec.x = max(maxVec.x, worldMax.x)
                    maxVec.y = max(maxVec.y, worldMax.y)
                    maxVec.z = max(maxVec.z, worldMax.z)
                }
            }
            
            if !hasGeometry {
                print("   ⚠️ Model has no geometry!")
                return false
            }
            
            // Calculate actual size
            let actualWidth = CGFloat(maxVec.x - minVec.x)
            let actualHeight = CGFloat(maxVec.y - minVec.y)
            let actualDepth = CGFloat(maxVec.z - minVec.z)
            
            print("   📏 Model dimensions: W:\(String(format: "%.2f", actualWidth))m H:\(String(format: "%.2f", actualHeight))m D:\(String(format: "%.2f", actualDepth))m")
            
            // Get desired dimensions
            let desiredWidth = CGFloat(catalogItem?.defaultDimensions.width ?? 1.0)
            let desiredHeight = CGFloat(catalogItem?.defaultDimensions.height ?? 1.0)
            let desiredDepth = CGFloat(catalogItem?.defaultDimensions.depth ?? 1.0)
            
            print("   🎯 Target dimensions: W:\(String(format: "%.2f", desiredWidth))m H:\(String(format: "%.2f", desiredHeight))m D:\(String(format: "%.2f", desiredDepth))m")
            
            // Calculate uniform scale
            let scaleX = actualWidth > 0.001 ? desiredWidth / actualWidth : 1.0
            let scaleY = actualHeight > 0.001 ? desiredHeight / actualHeight : 1.0
            let scaleZ = actualDepth > 0.001 ? desiredDepth / actualDepth : 1.0
            let uniformScale = min(scaleX, min(scaleY, scaleZ))
            
            print("   ⚖️ Applying scale: \(String(format: "%.3f", uniformScale))")
            
            // Add all child nodes
            for child in modelScene.rootNode.childNodes {
                let clonedChild = child.clone()
                clonedChild.scale = SCNVector3(uniformScale, uniformScale, uniformScale)
                
                // Center on X-Z plane, align bottom to Y=0
                let centerOffset = SCNVector3(
                    -(minVec.x + maxVec.x) / 2.0 * Float(uniformScale),
                    -minVec.y * Float(uniformScale),
                    -(minVec.z + maxVec.z) / 2.0 * Float(uniformScale)
                )
                clonedChild.position = centerOffset
                
                self.addChildNode(clonedChild)
            }
            
            return true
            
        } catch {
            print("   ❌ Error loading scene: \(error.localizedDescription)")
            return false
        }
    }
    
    private func createBasicGeometry() {
        let width = CGFloat(catalogItem?.defaultDimensions.width ?? 1.0)
        let height = CGFloat(catalogItem?.defaultDimensions.height ?? 1.0)
        let depth = CGFloat(catalogItem?.defaultDimensions.depth ?? 1.0)
        
        let geometry = SCNBox(
            width: width,
            height: height,
            length: depth,
            chamferRadius: 0.05
        )
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBrown
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.6
        material.metalness.contents = 0.1
        geometry.materials = [material]
        
        self.geometry = geometry
        print("   📦 Using basic box: \(String(format: "%.2f", width))m × \(String(format: "%.2f", height))m × \(String(format: "%.2f", depth))m")
    }
    
    func updateTransform() {
        // FIXED: Position - Y should be 0 for floor level since we centered the model
        // The model is already centered at Y=0 in setupGeometry
        position = SCNVector3(
            furnitureItem.position.x,
            0, // Keep on floor
            furnitureItem.position.z
        )
        
        // Rotation
        eulerAngles = SCNVector3(
            furnitureItem.rotation.x,
            furnitureItem.rotation.y,
            furnitureItem.rotation.z
        )
        
        // Scale
        scale = SCNVector3(
            furnitureItem.scale.x,
            furnitureItem.scale.y,
            furnitureItem.scale.z
        )
    }
}

// MARK: - Room Configuration

struct RoomConfiguration {
    let width: Double
    let length: Double
    let height: Double
    let wallThickness: Double
    
    static let defaultRoom = RoomConfiguration(
        width: 8.0,
        length: 10.0,
        height: 3.0,
        wallThickness: 0.2
    )
}
