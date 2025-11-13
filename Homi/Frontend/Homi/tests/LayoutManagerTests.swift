import XCTest
@testable import Homi

final class LayoutManagerTests: XCTestCase {
    
    var layoutManager: LayoutManager!
    
    override func setUp() {
        super.setUp()
        layoutManager = LayoutManager()
    }
    
    override func tearDown() {
        layoutManager = nil
        super.tearDown()
    }
    
    // MARK: - Layout Creation Tests
    
    func testCreateNewLayout() {
        layoutManager.createNewLayout(name: "Test Room")
        
        XCTAssertNotNil(layoutManager.currentLayout)
        XCTAssertEqual(layoutManager.currentLayout?.name, "Test Room")
        XCTAssertEqual(layoutManager.currentLayout?.userId, "default_user")
        XCTAssertTrue(layoutManager.currentLayout?.furnitureItems.isEmpty ?? false)
        XCTAssertTrue(layoutManager.furnitureNodes.isEmpty)
    }
    
    func testCreateNewLayoutWithEmptyName() {
        layoutManager.createNewLayout(name: "")
        
        XCTAssertNotNil(layoutManager.currentLayout)
        XCTAssertEqual(layoutManager.currentLayout?.name, "")
    }
    
    // MARK: - Layout Loading Tests
    
    func testLoadLayout() {
        let testLayout = Layout(
            id: "test_layout_id",
            userId: "test_user",
            name: "Loaded Layout",
            createdAt: Date(),
            furnitureItems: []
        )
        
        layoutManager.loadLayout(testLayout)
        
        XCTAssertNotNil(layoutManager.currentLayout)
        XCTAssertEqual(layoutManager.currentLayout?.id, "test_layout_id")
        XCTAssertEqual(layoutManager.currentLayout?.name, "Loaded Layout")
        XCTAssertEqual(layoutManager.currentLayout?.userId, "test_user")
    }
    
    func testLoadLayoutWithFurnitureItems() {
        let furnitureItem = FurnitureItem(
            id: "furniture_1",
            furnitureId: "catalog_sofa",
            position: Position(x: 1.0, y: 0, z: 2.0),
            rotation: Rotation(x: 0, y: 90, z: 0),
            scale: Scale(x: 1, y: 1, z: 1),
            properties: FurnitureProperties(color: "blue", material: "fabric")
        )
        
        let testLayout = Layout(
            id: "test_layout_id",
            userId: "test_user",
            name: "Layout with Furniture",
            createdAt: Date(),
            furnitureItems: [furnitureItem]
        )
        
        layoutManager.loadLayout(testLayout)
        
        XCTAssertNotNil(layoutManager.currentLayout)
        XCTAssertEqual(layoutManager.currentLayout?.furnitureItems.count, 1)
        XCTAssertEqual(layoutManager.furnitureNodes.count, 1)
    }
    
    // MARK: - Furniture Management Tests
    
    func testAddFurniture() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Sofa",
            type: "Sofa",
            defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
            materialOptions: ["fabric", "leather"],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        let position = SCNVector3(x: 1.0, y: 0, z: 2.0)
        layoutManager.addFurniture(catalogItem: catalogItem, at: position)
        
        XCTAssertEqual(layoutManager.currentLayout?.furnitureItems.count, 1)
        XCTAssertEqual(layoutManager.furnitureNodes.count, 1)
        
        let addedItem = layoutManager.currentLayout?.furnitureItems.first
        XCTAssertNotNil(addedItem)
        XCTAssertEqual(addedItem?.furnitureId, "catalog_1")
        XCTAssertEqual(addedItem?.position.x, 1.0)
        XCTAssertEqual(addedItem?.position.z, 2.0)
        XCTAssertEqual(addedItem?.position.y, 0)
    }
    
    func testAddFurnitureWithoutCurrentLayout() {
        // Don't create a layout first
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Sofa",
            type: "Sofa",
            defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        let position = SCNVector3(x: 1.0, y: 0, z: 2.0)
        layoutManager.addFurniture(catalogItem: catalogItem, at: position)
        
        // Should not add furniture if no layout exists
        XCTAssertNil(layoutManager.currentLayout)
        XCTAssertTrue(layoutManager.furnitureNodes.isEmpty)
    }
    
    func testRemoveFurniture() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Sofa",
            type: "Sofa",
            defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        let position = SCNVector3(x: 1.0, y: 0, z: 2.0)
        layoutManager.addFurniture(catalogItem: catalogItem, at: position)
        
        XCTAssertEqual(layoutManager.currentLayout?.furnitureItems.count, 1)
        
        let furnitureItem = layoutManager.currentLayout!.furnitureItems.first!
        layoutManager.removeFurniture(furnitureItem: furnitureItem)
        
        XCTAssertEqual(layoutManager.currentLayout?.furnitureItems.count, 0)
        XCTAssertEqual(layoutManager.furnitureNodes.count, 0)
    }
    
    func testRemoveFurnitureWithoutCurrentLayout() {
        let furnitureItem = FurnitureItem(
            id: "furniture_1",
            furnitureId: "catalog_sofa",
            position: Position(x: 1.0, y: 0, z: 2.0),
            rotation: Rotation(x: 0, y: 0, z: 0),
            scale: Scale(x: 1, y: 1, z: 1),
            properties: FurnitureProperties(color: "blue", material: "fabric")
        )
        
        layoutManager.removeFurniture(furnitureItem: furnitureItem)
        
        // Should not crash, just do nothing
        XCTAssertNil(layoutManager.currentLayout)
    }
    
    // MARK: - Furniture Position Update Tests
    
    func testUpdateFurniturePosition() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Chair",
            type: "Chair",
            defaultDimensions: Dimensions(width: 0.5, height: 0.9, depth: 0.5),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        layoutManager.addFurniture(catalogItem: catalogItem, at: SCNVector3(x: 0, y: 0, z: 0))
        
        let furnitureItem = layoutManager.currentLayout!.furnitureItems.first!
        let newPosition = SCNVector3(x: 3.0, y: 0, z: 4.0)
        layoutManager.updateFurniturePosition(furnitureItem, position: newPosition)
        
        let updatedItem = layoutManager.currentLayout?.furnitureItems.first
        XCTAssertEqual(updatedItem?.position.x, 3.0)
        XCTAssertEqual(updatedItem?.position.z, 4.0)
        XCTAssertEqual(updatedItem?.position.y, 0)
    }
    
    // MARK: - Furniture Rotation Update Tests
    
    func testUpdateFurnitureRotation() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Table",
            type: "Table",
            defaultDimensions: Dimensions(width: 1.0, height: 0.4, depth: 0.6),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        layoutManager.addFurniture(catalogItem: catalogItem, at: SCNVector3(x: 0, y: 0, z: 0))
        
        let furnitureItem = layoutManager.currentLayout!.furnitureItems.first!
        let newRotation = SCNVector3(x: 0, y: 90, z: 0)
        layoutManager.updateFurnitureRotation(furnitureItem, rotation: newRotation)
        
        let updatedItem = layoutManager.currentLayout?.furnitureItems.first
        XCTAssertEqual(updatedItem?.rotation.y, 90)
    }
    
    // MARK: - Furniture Scale Update Tests
    
    func testUpdateFurnitureScale() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let catalogItem = CatalogItem(
            id: "catalog_1",
            name: "Test Lamp",
            type: "Lighting",
            defaultDimensions: Dimensions(width: 0.3, height: 0.5, depth: 0.3),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        layoutManager.addFurniture(catalogItem: catalogItem, at: SCNVector3(x: 0, y: 0, z: 0))
        
        let furnitureItem = layoutManager.currentLayout!.furnitureItems.first!
        let newScale = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
        layoutManager.updateFurnitureScale(furnitureItem, scale: newScale)
        
        let updatedItem = layoutManager.currentLayout?.furnitureItems.first
        XCTAssertEqual(updatedItem?.scale.x, 1.5)
        XCTAssertEqual(updatedItem?.scale.y, 1.5)
        XCTAssertEqual(updatedItem?.scale.z, 1.5)
    }
    
    // MARK: - Catalog Item Lookup Tests
    
    func testGetCatalogItemById() {
        let catalogItem = CatalogItem(
            id: "catalog_123",
            name: "Test Item",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 1.0, depth: 1.0),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        // Manually set catalog items for testing
        layoutManager.catalogItems = [catalogItem]
        
        let foundItem = layoutManager.getCatalogItem(by: "catalog_123")
        XCTAssertNotNil(foundItem)
        XCTAssertEqual(foundItem?.id, "catalog_123")
        XCTAssertEqual(foundItem?.name, "Test Item")
    }
    
    func testGetCatalogItemByIdNotFound() {
        let catalogItem = CatalogItem(
            id: "catalog_123",
            name: "Test Item",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 1.0, depth: 1.0),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        layoutManager.catalogItems = [catalogItem]
        
        let foundItem = layoutManager.getCatalogItem(by: "nonexistent_id")
        XCTAssertNil(foundItem)
    }
    
    // MARK: - Multiple Furniture Items Tests
    
    func testAddMultipleFurnitureItems() {
        layoutManager.createNewLayout(name: "Test Room")
        
        let sofa = CatalogItem(
            id: "catalog_sofa",
            name: "Sofa",
            type: "Sofa",
            defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        let chair = CatalogItem(
            id: "catalog_chair",
            name: "Chair",
            type: "Chair",
            defaultDimensions: Dimensions(width: 0.5, height: 0.9, depth: 0.5),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        layoutManager.addFurniture(catalogItem: sofa, at: SCNVector3(x: 0, y: 0, z: 0))
        layoutManager.addFurniture(catalogItem: chair, at: SCNVector3(x: 2, y: 0, z: 1))
        
        XCTAssertEqual(layoutManager.currentLayout?.furnitureItems.count, 2)
        XCTAssertEqual(layoutManager.furnitureNodes.count, 2)
    }
}

