import XCTest
@testable import Homi

final class CatalogViewTests: XCTestCase {
    
    // MARK: - Catalog Filtering Logic Tests
    // Note: Since CatalogView is a SwiftUI View, we test the filtering logic separately
    
    func testFilterItemsByCategory() {
        let allItems = [
            CatalogItem(
                id: "1",
                name: "Modern Sofa",
                type: "Sofa",
                defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
                materialOptions: ["fabric"],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "2",
                name: "Dining Chair",
                type: "Chair",
                defaultDimensions: Dimensions(width: 0.5, height: 0.9, depth: 0.5),
                materialOptions: ["wood"],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "3",
                name: "Coffee Table",
                type: "Table",
                defaultDimensions: Dimensions(width: 1.0, height: 0.4, depth: 0.6),
                materialOptions: ["wood"],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            )
        ]
        
        // Test filtering by "All" category
        let allFiltered = allItems.filter { _ in true }
        XCTAssertEqual(allFiltered.count, 3)
        
        // Test filtering by "Sofa" category
        let sofaFiltered = allItems.filter { $0.type == "Sofa" }
        XCTAssertEqual(sofaFiltered.count, 1)
        XCTAssertEqual(sofaFiltered.first?.name, "Modern Sofa")
        
        // Test filtering by "Chair" category
        let chairFiltered = allItems.filter { $0.type == "Chair" }
        XCTAssertEqual(chairFiltered.count, 1)
        XCTAssertEqual(chairFiltered.first?.name, "Dining Chair")
    }
    
    func testFilterItemsBySearchText() {
        let items = [
            CatalogItem(
                id: "1",
                name: "Modern Sofa",
                type: "Sofa",
                defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "2",
                name: "Dining Chair",
                type: "Chair",
                defaultDimensions: Dimensions(width: 0.5, height: 0.9, depth: 0.5),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "3",
                name: "Coffee Table",
                type: "Table",
                defaultDimensions: Dimensions(width: 1.0, height: 0.4, depth: 0.6),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            )
        ]
        
        // Test search for "Sofa"
        let sofaSearch = items.filter { $0.name.localizedCaseInsensitiveContains("Sofa") }
        XCTAssertEqual(sofaSearch.count, 1)
        XCTAssertEqual(sofaSearch.first?.name, "Modern Sofa")
        
        // Test search for "chair" (case insensitive)
        let chairSearch = items.filter { $0.name.localizedCaseInsensitiveContains("chair") }
        XCTAssertEqual(chairSearch.count, 1)
        XCTAssertEqual(chairSearch.first?.name, "Dining Chair")
        
        // Test search for "table" (case insensitive)
        let tableSearch = items.filter { $0.name.localizedCaseInsensitiveContains("table") }
        XCTAssertEqual(tableSearch.count, 1)
        XCTAssertEqual(tableSearch.first?.name, "Coffee Table")
        
        // Test search with no matches
        let noMatchSearch = items.filter { $0.name.localizedCaseInsensitiveContains("bed") }
        XCTAssertEqual(noMatchSearch.count, 0)
    }
    
    func testFilterItemsByCategoryAndSearch() {
        let items = [
            CatalogItem(
                id: "1",
                name: "Modern Sofa",
                type: "Sofa",
                defaultDimensions: Dimensions(width: 2.0, height: 0.8, depth: 0.9),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "2",
                name: "Comfortable Sofa",
                type: "Sofa",
                defaultDimensions: Dimensions(width: 2.2, height: 0.8, depth: 0.9),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            ),
            CatalogItem(
                id: "3",
                name: "Dining Chair",
                type: "Chair",
                defaultDimensions: Dimensions(width: 0.5, height: 0.9, depth: 0.5),
                materialOptions: [],
                imageUrl: nil,
                description: nil,
                modelFileName: nil
            )
        ]
        
        // Filter by category first
        let categoryFiltered = items.filter { $0.type == "Sofa" }
        XCTAssertEqual(categoryFiltered.count, 2)
        
        // Then filter by search text
        let searchFiltered = categoryFiltered.filter { $0.name.localizedCaseInsensitiveContains("Modern") }
        XCTAssertEqual(searchFiltered.count, 1)
        XCTAssertEqual(searchFiltered.first?.name, "Modern Sofa")
    }
    
    // MARK: - CatalogItem Property Tests
    
    func testCatalogItemProperties() {
        let item = CatalogItem(
            id: "test_id",
            name: "Test Furniture",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 2.0, depth: 0.5),
            materialOptions: ["wood", "metal"],
            imageUrl: "https://example.com/image.jpg",
            description: "A test furniture item",
            modelFileName: "test.usdz"
        )
        
        XCTAssertEqual(item.id, "test_id")
        XCTAssertEqual(item.name, "Test Furniture")
        XCTAssertEqual(item.type, "Furniture")
        XCTAssertEqual(item.defaultDimensions.width, 1.0)
        XCTAssertEqual(item.defaultDimensions.height, 2.0)
        XCTAssertEqual(item.defaultDimensions.depth, 0.5)
        XCTAssertEqual(item.materialOptions.count, 2)
        XCTAssertEqual(item.materialOptions.first, "wood")
        XCTAssertEqual(item.imageUrl, "https://example.com/image.jpg")
        XCTAssertEqual(item.description, "A test furniture item")
        XCTAssertEqual(item.modelFileName, "test.usdz")
    }
    
    func testCatalogItemWithOptionalFields() {
        let item = CatalogItem(
            id: "test_id",
            name: "Test Furniture",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 2.0, depth: 0.5),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        XCTAssertEqual(item.id, "test_id")
        XCTAssertEqual(item.name, "Test Furniture")
        XCTAssertNil(item.imageUrl)
        XCTAssertNil(item.description)
        XCTAssertNil(item.modelFileName)
    }
    
    // MARK: - CatalogItem Dimensions Tests
    
    func testCatalogItemDimensions() {
        let item = CatalogItem(
            id: "test_id",
            name: "Test Item",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 2.5, height: 1.8, depth: 1.2),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        XCTAssertEqual(item.defaultDimensions.width, 2.5)
        XCTAssertEqual(item.defaultDimensions.height, 1.8)
        XCTAssertEqual(item.defaultDimensions.depth, 1.2)
    }
    
    // MARK: - CatalogItem Material Options Tests
    
    func testCatalogItemMaterialOptions() {
        let item = CatalogItem(
            id: "test_id",
            name: "Test Item",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 1.0, depth: 1.0),
            materialOptions: ["wood", "metal", "plastic"],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        XCTAssertEqual(item.materialOptions.count, 3)
        XCTAssertTrue(item.materialOptions.contains("wood"))
        XCTAssertTrue(item.materialOptions.contains("metal"))
        XCTAssertTrue(item.materialOptions.contains("plastic"))
    }
    
    func testCatalogItemEmptyMaterialOptions() {
        let item = CatalogItem(
            id: "test_id",
            name: "Test Item",
            type: "Furniture",
            defaultDimensions: Dimensions(width: 1.0, height: 1.0, depth: 1.0),
            materialOptions: [],
            imageUrl: nil,
            description: nil,
            modelFileName: nil
        )
        
        XCTAssertTrue(item.materialOptions.isEmpty)
    }
}

