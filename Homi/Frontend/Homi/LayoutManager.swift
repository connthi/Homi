import Foundation
import SwiftUI
import SceneKit
import Combine

class LayoutManager: ObservableObject {
    @Published var currentLayout: Layout?
    @Published var furnitureNodes: [FurnitureNode] = []
    @Published var catalogItems: [CatalogItem] = []
    @Published var isCatalogLoaded = false

    private let apiService = APIService.shared

    init() {
        Task { await loadCatalog() }
    }

    // MARK: - Layout Management

    func createNewLayout(name: String) {
        let newLayout = Layout(
            id: nil,
            userId: "default_user",
            name: name,
            createdAt: Date(),
            furnitureItems: []
        )
        currentLayout = newLayout
        furnitureNodes = []
    }

    func loadLayout(_ layout: Layout) {
        currentLayout = layout
        updateFurnitureNodes()
    }

    func saveCurrentLayout() async throws {
        guard let layout = currentLayout else { return }

        if layout.id == nil || layout.id?.isEmpty == true {
            let savedLayout = try await apiService.saveLayout(layout)
            await MainActor.run { self.currentLayout = savedLayout }
        } else {
            let updatedLayout = try await apiService.updateLayout(layout)
            await MainActor.run { self.currentLayout = updatedLayout }
        }
    }

    func updateCurrentLayout() async throws {
        guard let layout = currentLayout else { return }
        let updatedLayout = try await apiService.updateLayout(layout)
        await MainActor.run { self.currentLayout = updatedLayout }
    }

    // MARK: - Furniture Management

    func addFurniture(catalogItem: CatalogItem, at position: SCNVector3) {
        guard let layout = currentLayout else { return }

        let newFurnitureItem = FurnitureItem(
            id: nil,
            furnitureId: catalogItem.id,
            position: Position(x: Double(position.x), y: 0, z: Double(position.z)),
            rotation: Rotation(x: 0, y: 0, z: 0),
            scale: Scale(x: 1, y: 1, z: 1),
            properties: FurnitureProperties(color: "brown", material: "wood")
        )

        var updatedFurnitureItems = layout.furnitureItems
        updatedFurnitureItems.append(newFurnitureItem)

        let updatedLayout = Layout(
            id: layout.id,                       
            userId: layout.userId,
            name: layout.name,
            createdAt: layout.createdAt,
            furnitureItems: updatedFurnitureItems
        )

        currentLayout = updatedLayout
        updateFurnitureNodes()
    }

    func removeFurniture(furnitureItem: FurnitureItem) {
        guard let layout = currentLayout else { return }

        let updatedFurnitureItems = layout.furnitureItems.filter { $0.id != furnitureItem.id }

        let updatedLayout = Layout(
            id: layout.id,
            userId: layout.userId,
            name: layout.name,
            createdAt: layout.createdAt,
            furnitureItems: updatedFurnitureItems
        )

        currentLayout = updatedLayout
        updateFurnitureNodes()
    }

    func updateFurniturePosition(_ furnitureItem: FurnitureItem, position: SCNVector3) {
        guard let layout = currentLayout else { return }

        let updatedPosition = Position(x: Double(position.x), y: 0, z: Double(position.z))

        let updatedFurnitureItems = layout.furnitureItems.map { item in
            if item.id == furnitureItem.id {
                return FurnitureItem(
                    id: item.id,
                    furnitureId: item.furnitureId,
                    position: updatedPosition,
                    rotation: item.rotation,
                    scale: item.scale,
                    properties: item.properties
                )
            }
            return item
        }

        let updatedLayout = Layout(
            id: layout.id,
            userId: layout.userId,
            name: layout.name,
            createdAt: layout.createdAt,
            furnitureItems: updatedFurnitureItems
        )

        currentLayout = updatedLayout
        updateFurnitureNodes()
    }

    func updateFurnitureRotation(_ furnitureItem: FurnitureItem, rotation: SCNVector3) {
        guard let layout = currentLayout else { return }

        let updatedRotation = Rotation(x: Double(rotation.x), y: Double(rotation.y), z: Double(rotation.z))

        let updatedFurnitureItems = layout.furnitureItems.map { item in
            if item.id == furnitureItem.id {
                return FurnitureItem(
                    id: item.id,
                    furnitureId: item.furnitureId,
                    position: item.position,
                    rotation: updatedRotation,
                    scale: item.scale,
                    properties: item.properties
                )
            }
            return item
        }

        let updatedLayout = Layout(
            id: layout.id,
            userId: layout.userId,
            name: layout.name,
            createdAt: layout.createdAt,
            furnitureItems: updatedFurnitureItems
        )

        currentLayout = updatedLayout
        updateFurnitureNodes()
    }

    func updateFurnitureScale(_ furnitureItem: FurnitureItem, scale: SCNVector3) {
        guard let layout = currentLayout else { return }

        let updatedScale = Scale(x: Double(scale.x), y: Double(scale.y), z: Double(scale.z))

        let updatedFurnitureItems = layout.furnitureItems.map { item in
            if item.id == furnitureItem.id {
                return FurnitureItem(
                    id: item.id,
                    furnitureId: item.furnitureId,
                    position: item.position,
                    rotation: item.rotation,
                    scale: updatedScale,
                    properties: item.properties
                )
            }
            return item
        }

        let updatedLayout = Layout(
            id: layout.id,
            userId: layout.userId,
            name: layout.name,
            createdAt: layout.createdAt,
            furnitureItems: updatedFurnitureItems
        )

        currentLayout = updatedLayout
        updateFurnitureNodes()
    }

    private func updateFurnitureNodes() {
        guard let layout = currentLayout else {
            furnitureNodes = []
            return
        }

        furnitureNodes = layout.furnitureItems.map { furnitureItem in
            let catalogItem = catalogItems.first { $0.id == furnitureItem.furnitureId }
            return FurnitureNode(furnitureItem: furnitureItem, catalogItem: catalogItem)
        }
    }

    @MainActor
    func loadCatalog() async {
        do {
            let items = try await APIService.shared.fetchCatalog()
            self.catalogItems = items
            self.isCatalogLoaded = true

            if let firstItem = items.first {
                print("✅ Successfully loaded \(items.count) items from catalog!")
                print("First item: \(firstItem.name)")
            } else {
                print("⚠️ Catalog loaded but was empty.")
            }
        } catch {
            print("❌ Failed to load catalog: \(error.localizedDescription)")
        }
    }

    func getCatalogItem(by id: String) -> CatalogItem? {
        catalogItems.first { $0.id == id }
    }
}