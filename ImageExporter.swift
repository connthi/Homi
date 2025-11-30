import SwiftUI
import SceneKit
import Photos

/// Handles exporting a rendered room layout image to the user's photo library.
class ImageExporter {
    static let shared = ImageExporter()
    
    /// Renders the current room layout from a fixed camera angle and saves it to Photos.
    func exportRoomLayout(
        scene: SCNScene,
        furnitureNodes: [FurnitureNode],
        roomConfig: EditableRoom,
        wallColor: UIColor,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Temporary rendering scene view
        let renderView = SCNView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        renderView.scene = scene
        renderView.backgroundColor = .white
        renderView.antialiasingMode = .multisampling4X
        
        // Export camera configuration
        let exportCamera = SCNNode()
        exportCamera.camera = SCNCamera()
        exportCamera.camera?.zFar = 100
        exportCamera.camera?.fieldOfView = 65
        
        // Calculate camera placement based on room size
        let roomWidth = CGFloat(roomConfig.width)
        let roomLength = CGFloat(roomConfig.length)
        let roomHeight = CGFloat(roomConfig.height)
        
        let roomDiagonal = sqrt(roomWidth * roomWidth + roomLength * roomLength)
        let distance = roomDiagonal * 0.9
        
        // Position camera in a 3/4 perspective for clear visibility
        exportCamera.position = SCNVector3(
            Float(distance * 0.65),
            Float(roomHeight * 1.2),
            Float(distance * 0.65)
        )
        
        // Aim camera toward the room center
        exportCamera.look(at: SCNVector3(0, Float(roomHeight * 0.25), 0))
        
        scene.rootNode.addChildNode(exportCamera)
        renderView.pointOfView = exportCamera
        
        // Hide specific walls to improve visibility for export
        hideWallsForExport(scene: scene, show: false)
        
        // Allow SceneKit time to render before snapshotting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = renderView.snapshot()
            
            // Restore scene state
            self.hideWallsForExport(scene: scene, show: true)
            exportCamera.removeFromParentNode()
            
            // Save snapshot to Photos
            self.saveToPhotos(image: image, completion: completion)
        }
    }
    
    /// Toggles visibility of selected walls during export rendering.
    private func hideWallsForExport(scene: SCNScene, show: Bool) {
        let wallNames = ["frontWall", "rightWall"]
        
        for wallName in wallNames {
            if let wall = scene.rootNode.childNode(withName: wallName, recursively: false) {
                wall.isHidden = !show
            }
        }
    }
    
    /// Saves a rendered UIImage to the user's photo library.
    private func saveToPhotos(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "ImageExporter",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey:
                            "Photo library access denied. Please enable access in Settings."]
                    )))
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? NSError(
                            domain: "ImageExporter",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to save image"]
                        )))
                    }
                }
            }
        }
    }
}