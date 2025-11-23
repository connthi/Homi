import SwiftUI
import SceneKit
import Photos

class ImageExporter {
    static let shared = ImageExporter()
    
    func exportRoomLayout(
        scene: SCNScene,
        furnitureNodes: [FurnitureNode],
        roomConfig: EditableRoom,
        wallColor: UIColor,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Create a temporary scene view for rendering
        let renderView = SCNView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        renderView.scene = scene
        renderView.backgroundColor = .white
        renderView.antialiasingMode = .multisampling4X
        
        // Setup export camera at optimal angle
        let exportCamera = SCNNode()
        exportCamera.camera = SCNCamera()
        exportCamera.camera?.zFar = 100
        exportCamera.camera?.fieldOfView = 65
        
        // Better camera positioning - closer and more dynamic
        let roomWidth = CGFloat(roomConfig.width)
        let roomLength = CGFloat(roomConfig.length)
        let roomHeight = CGFloat(roomConfig.height)
        
        let roomDiagonal = sqrt(roomWidth * roomWidth + roomLength * roomLength)
        let distance = roomDiagonal * 0.9
        
        // Position camera at a nice 3/4 view angle
        exportCamera.position = SCNVector3(
            Float(distance * 0.65),  
            Float(roomHeight * 1.2),
            Float(distance * 0.65)
        )
        
        // Look at the center of the room, slightly elevated
        exportCamera.look(at: SCNVector3(0, Float(roomHeight * 0.25), 0))
        
        scene.rootNode.addChildNode(exportCamera)
        renderView.pointOfView = exportCamera
        
        // Hide front walls for better view
        hideWallsForExport(scene: scene, show: false)
        
        // Render the image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = renderView.snapshot()
            
            // Restore walls
            self.hideWallsForExport(scene: scene, show: true)
            exportCamera.removeFromParentNode()
            
            // Save to photo library
            self.saveToPhotos(image: image, completion: completion)
        }
    }
    
    private func hideWallsForExport(scene: SCNScene, show: Bool) {
        let wallNames = ["frontWall", "rightWall"]
        
        for wallName in wallNames {
            if let wall = scene.rootNode.childNode(withName: wallName, recursively: false) {
                wall.isHidden = !show
            }
        }
    }
    
    private func saveToPhotos(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "ImageExporter",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Photo library access denied. Please enable access in Settings."]
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