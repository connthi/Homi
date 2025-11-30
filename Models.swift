import Foundation
import SceneKit

// MARK: - Authentication Models

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct AuthResponse: Codable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: TimeInterval
    let refreshTokenExpiresAt: TimeInterval
    let user: User
}

struct UserEnvelope: Codable {
    let user: User
}

// MARK: - Layout + Furniture Models (Backend-Aligned)

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

// Represents a single furniture instance placed in a layout
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
    
    // Custom encoding ignores UUID strings and lets the server assign real MongoDB ObjectIds
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if id.count == 24 && id.allSatisfy({ $0.isHexDigit }) {
            try container.encode(id, forKey: .id)
        }
        
        try container.encode(furnitureId, forKey: .furnitureId)
        try container.encode(position, forKey: .position)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scale, forKey: .scale)
        try container.encode(properties, forKey: .properties)
    }
}

// MARK: - Basic Components

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

// MARK: - Catalog Items

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

// MARK: - SceneKit Furniture Node
// Wraps a FurnitureItem in a 3D SceneKit node and loads either USDZ models or fallback geometry.

class FurnitureNode: SCNNode {
    let furnitureItem: FurnitureItem
    let catalogItem: CatalogItem?
    private static var hasDebugPrinted = false
    
    init(furnitureItem: FurnitureItem, catalogItem: CatalogItem? = nil) {
        self.furnitureItem = furnitureItem
        self.catalogItem = catalogItem
        super.init()
        
        // Print bundle model files once for debugging
        if !FurnitureNode.hasDebugPrinted {
            printBundleResources()
            FurnitureNode.hasDebugPrinted = true
        }
        
        // Build geometry immediately so the node is ready for placement
        setupGeometry()
        updateTransform()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Prints the available .usdz files in the bundle (debug use)
    private func printBundleResources() {
        print("\n📁 === BUNDLE RESOURCES DEBUG ===")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let usdzFiles = contents.filter { $0.hasSuffix(".usdz") }
                
                print("📦 Found \(usdzFiles.count) USDZ files:")
                for file in usdzFiles { print("   \(file)") }
                
                if usdzFiles.isEmpty {
                    print("⚠️ No USDZ models found in bundle.")
                }
            } catch {
                print("❌ Error reading bundle: \(error)")
            }
        }
        print("=================================\n")
    }
    
    // Loads USDZ model file or falls back to a simple box if unavailable
    private func setupGeometry() {
        guard let modelFileName = catalogItem?.modelFileName, !modelFileName.isEmpty else {
            createBasicGeometry()
            return
        }
        
        let variations = [
            modelFileName,
            "\(modelFileName).usdz",
            modelFileName.replacingOccurrences(of: ".usdz", with: "")
        ]
        
        var loaded = false
        for variant in variations {
            let cleanName = variant.replacingOccurrences(of: ".usdz", with: "")
            if let url = Bundle.main.url(forResource: cleanName, withExtension: "usdz"),
               loadUSDZModel(from: url) {
                loaded = true
                break
            }
        }
        
        if !loaded {
            createBasicGeometry()
        }
    }
    
    // Parses and loads a USDZ file, applying automatic scaling and centering
    private func loadUSDZModel(from url: URL) -> Bool {
        do {
            let modelScene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .flattenScene: false
            ])
            
            // Compute bounding box across all nodes with geometry
            var minVec = SCNVector3(Float.greatestFiniteMagnitude,
                                    Float.greatestFiniteMagnitude,
                                    Float.greatestFiniteMagnitude)
            var maxVec = SCNVector3(-Float.greatestFiniteMagnitude,
                                    -Float.greatestFiniteMagnitude,
                                    -Float.greatestFiniteMagnitude)
            var hasGeometry = false
            
            modelScene.rootNode.enumerateChildNodes { node, _ in
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
            
            if !hasGeometry { return false }
            
            // Dimensions of the model
            let actualWidth = CGFloat(maxVec.x - minVec.x)
            let actualHeight = CGFloat(maxVec.y - minVec.y)
            let actualDepth = CGFloat(maxVec.z - minVec.z)
            
            // Desired size based on catalog metadata
            let desired = catalogItem?.defaultDimensions ?? Dimensions(width: 1, height: 1, depth: 1)
            
            // Uniform scale to fit within desired dimensions
            let scaleX = desired.width / max(actualWidth, 0.001)
            let scaleY = desired.height / max(actualHeight, 0.001)
            let scaleZ = desired.depth / max(actualDepth, 0.001)
            let uniformScale = min(scaleX, min(scaleY, scaleZ))
            
            // Clone and insert all child nodes from the model scene
            for child in modelScene.rootNode.childNodes {
                let clone = child.clone()
                clone.scale = SCNVector3(uniformScale, uniformScale, uniformScale)
                
                // Center and lift model so it sits on Y = 0
                let offset = SCNVector3(
                    -(minVec.x + maxVec.x) / 2 * Float(uniformScale),
                    -minVec.y * Float(uniformScale),
                    -(minVec.z + maxVec.z) / 2 * Float(uniformScale)
                )
                clone.position = offset
                
                addChildNode(clone)
            }
            
            return true
            
        } catch {
            return false
        }
    }
    
    // Fallback when model loading fails
    private func createBasicGeometry() {
        let dims = catalogItem?.defaultDimensions ?? Dimensions(width: 1, height: 1, depth: 1)
        
        let box = SCNBox(
            width: dims.width,
            height: dims.height,
            length: dims.depth,
            chamferRadius: 0.05
        )
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBrown
        material.lightingModel = .physicallyBased
        
        box.materials = [material]
        self.geometry = box
    }
    
    // Applies saved position, rotation, and scale to the SceneKit node
    func updateTransform() {
        position = SCNVector3(furnitureItem.position.x, 0, furnitureItem.position.z)
        
        eulerAngles = SCNVector3(
            furnitureItem.rotation.x,
            furnitureItem.rotation.y,
            furnitureItem.rotation.z
        )
        
        scale = SCNVector3(
            furnitureItem.scale.x,
            furnitureItem.scale.y,
            furnitureItem.scale.z
        )
    }
    
    // Ensures geometry exists before rendering
    func setupGeometryIfNeeded() {
        if geometry == nil && childNodes.isEmpty {
            setupGeometry()
            updateTransform()
        }
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