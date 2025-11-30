import XCTest
@testable import Homi

final class ModelsTests: XCTestCase {
    
    // MARK: - Layout Tests
    
    func testLayoutDecoding() throws {
        let json = """
        {
            "_id": "507f1f77bcf86cd799439011",
            "userId": "user123",
            "name": "Test Layout",
            "createdAt": "2025-10-17T05:33:12.925Z",
            "furnitureItems": []
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let layout = try decoder.decode(Layout.self, from: json)
        
        XCTAssertEqual(layout.id, "507f1f77bcf86cd799439011")
        XCTAssertEqual(layout.userId, "user123")
        XCTAssertEqual(layout.name, "Test Layout")
        XCTAssertTrue(layout.furnitureItems.isEmpty)
    }
    
    func testLayoutEncodingDecoding() throws {
        let originalLayout = Layout(
            id: "test123",
            userId: "user456",
            name: "Living Room",
            createdAt: Date(),
            furnitureItems: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalLayout)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedLayout = try decoder.decode(Layout.self, from: data)
        
        XCTAssertEqual(originalLayout.id, decodedLayout.id)
        XCTAssertEqual(originalLayout.name, decodedLayout.name)
        XCTAssertEqual(originalLayout.userId, decodedLayout.userId)
    }
    
    func testLayoutWithMultipleFurnitureItems() throws {
        let json = """
        {
            "_id": "507f1f77bcf86cd799439011",
            "userId": "user123",
            "name": "Test Layout",
            "createdAt": "2025-10-17T05:33:12.925Z",
            "furnitureItems": [
                {
                    "_id": "item1",
                    "furnitureId": "sofa1",
                    "position": {"x": 0, "y": 0, "z": 0},
                    "rotation": {"x": 0, "y": 0, "z": 0},
                    "scale": {"x": 1, "y": 1, "z": 1},
                    "properties": {"color": "blue", "material": "fabric"}
                },
                {
                    "_id": "item2",
                    "furnitureId": "table1",
                    "position": {"x": 2, "y": 0, "z": 1},
                    "rotation": {"x": 0, "y": 90, "z": 0},
                    "scale": {"x": 1, "y": 1, "z": 1},
                    "properties": {"color": "brown", "material": "wood"}
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let layout = try decoder.decode(Layout.self, from: json)
        
        XCTAssertEqual(layout.furnitureItems.count, 2)
        XCTAssertEqual(layout.furnitureItems[0].id, "item1")
        XCTAssertEqual(layout.furnitureItems[1].id, "item2")
        XCTAssertEqual(layout.furnitureItems[0].properties.color, "blue")
        XCTAssertEqual(layout.furnitureItems[1].properties.material, "wood")
    }
    
    // MARK: - FurnitureItem Tests
    
    func testFurnitureItemDecoding() throws {
        let json = """
        {
            "_id": "item123",
            "furnitureId": "sofa1",
            "position": {"x": 1.5, "y": 0.5, "z": 2.0},
            "rotation": {"x": 0, "y": 45, "z": 0},
            "scale": {"x": 1.2, "y": 1.0, "z": 1.0},
            "properties": {"color": "red", "material": "leather"}
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let item = try decoder.decode(FurnitureItem.self, from: json)
        
        XCTAssertEqual(item.id, "item123")
        XCTAssertEqual(item.furnitureId, "sofa1")
        XCTAssertEqual(item.position.x, 1.5)
        XCTAssertEqual(item.rotation.y, 45)
        XCTAssertEqual(item.scale.x, 1.2)
        XCTAssertEqual(item.properties.color, "red")
    }
    
    // MARK: - CatalogItem Tests
    
    func testCatalogItemDecoding() throws {
        let json = """
        {
            "_id": "catalog123",
            "name": "Modern Sofa",
            "type": "Sofa",
            "defaultDimensions": {"width": 2.0, "height": 0.8, "depth": 0.9},
            "materialOptions": ["leather", "fabric", "velvet"]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let item = try decoder.decode(CatalogItem.self, from: json)
        
        XCTAssertEqual(item.id, "catalog123")
        XCTAssertEqual(item.name, "Modern Sofa")
        XCTAssertEqual(item.type, "Sofa")
        XCTAssertEqual(item.defaultDimensions.width, 2.0)
        XCTAssertEqual(item.materialOptions.count, 3)
        XCTAssertTrue(item.materialOptions.contains("leather"))
    }
    
    func testCatalogItemArrayDecoding() throws {
        let json = """
        [
            {
                "_id": "catalog1",
                "name": "Modern Sofa",
                "type": "Sofa",
                "defaultDimensions": {"width": 2.0, "height": 0.8, "depth": 0.9},
                "materialOptions": ["leather"]
            },
            {
                "_id": "catalog2",
                "name": "Dining Chair",
                "type": "Chair",
                "defaultDimensions": {"width": 0.5, "height": 0.9, "depth": 0.5},
                "materialOptions": ["wood"]
            }
        ]
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let items = try decoder.decode([CatalogItem].self, from: json)
        
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].type, "Sofa")
        XCTAssertEqual(items[1].type, "Chair")
    }
    
    // MARK: - Position/Rotation/Scale Tests
    
    func testPositionDecoding() throws {
        let json = """
        {"x": 1.5, "y": 2.0, "z": 3.5}
        """.data(using: .utf8)!
        
        let position = try JSONDecoder().decode(Position.self, from: json)
        
        XCTAssertEqual(position.x, 1.5)
        XCTAssertEqual(position.y, 2.0)
        XCTAssertEqual(position.z, 3.5)
    }
    
    func testRotationDecoding() throws {
        let json = """
        {"x": 0, "y": 90, "z": 0}
        """.data(using: .utf8)!
        
        let rotation = try JSONDecoder().decode(Rotation.self, from: json)
        
        XCTAssertEqual(rotation.x, 0)
        XCTAssertEqual(rotation.y, 90)
        XCTAssertEqual(rotation.z, 0)
    }
    
    func testScaleDecoding() throws {
        let json = """
        {"x": 1.5, "y": 1.0, "z": 1.2}
        """.data(using: .utf8)!
        
        let scale = try JSONDecoder().decode(Scale.self, from: json)
        
        XCTAssertEqual(scale.x, 1.5)
        XCTAssertEqual(scale.y, 1.0)
        XCTAssertEqual(scale.z, 1.2)
    }
    
    // MARK: - RoomConfiguration Tests
    
    func testDefaultRoomConfiguration() {
        let room = RoomConfiguration.defaultRoom
        
        XCTAssertEqual(room.width, 4.0)
        XCTAssertEqual(room.length, 6.0)
        XCTAssertEqual(room.height, 2.5)
        XCTAssertEqual(room.wallThickness, 0.2)
    }
}