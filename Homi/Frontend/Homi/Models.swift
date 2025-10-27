import Foundation
import SceneKit

// MARK: - Data Models matching backend API

struct Layout: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let createdAt: Date
    let furnitureItems: [FurnitureItem]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, name, createdAt, furnitureItems
    }
    
    // Convenience init for creating new layouts
    init(id: String, userId: String, name: String, createdAt: Date, furnitureItems: [FurnitureItem]) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.furnitureItems = furnitureItems
    }
}

struct FurnitureItem: Codable, Identifiable {
    let id: String
    let furnitureId: String
    let position: Position
    let rotation: Rotation
    let scale: Scale
    let properties: FurnitureProperties
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case furnitureId, position, rotation, scale, properties
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
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, type, defaultDimensions, materialOptions, imageUrl, description
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
        
        setupGeometry()
        updateTransform()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGeometry() {
        // Create a basic box geometry for furniture
        let geometry = SCNBox(
            width: CGFloat(catalogItem?.defaultDimensions.width ?? 1.0),
            height: CGFloat(catalogItem?.defaultDimensions.height ?? 1.0),
            length: CGFloat(catalogItem?.defaultDimensions.depth ?? 1.0),
            chamferRadius: 0.1
        )
        
        // Apply material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(named: furnitureItem.properties.color) ?? UIColor.brown
        geometry.materials = [material]
        
        self.geometry = geometry
    }
    
    func updateTransform() {
        // Update position - ensure Y is at proper floor level
        let yPosition = catalogItem?.defaultDimensions.height ?? furnitureItem.position.y
        position = SCNVector3(
            furnitureItem.position.x,
            Double(Float(yPosition)) / 2.0, // Half height to sit on floor
            furnitureItem.position.z
        )
        
        // Update rotation
        eulerAngles = SCNVector3(
            furnitureItem.rotation.x,
            furnitureItem.rotation.y,
            furnitureItem.rotation.z
        )
        
        // Update scale
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
        width: 4.0,
        length: 6.0,
        height: 2.5,
        wallThickness: 0.2
    )
}
