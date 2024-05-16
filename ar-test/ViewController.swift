//
//  ViewController.swift
//  ar-test
//
//  Created by Dason Tiovino on 27/05/24.
//

import Foundation
import UIKit
import Vision
import RealityKit
import FocusEntity
import ARKit
import UIKit
import SwiftUI
import RealityKit
import AVFoundation
import Combine

var placedEntity: ModelEntity?

class ViewController: UIViewController, ARSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ARCoachingOverlayViewDelegate  {
    
    private var videoLooper: AVPlayerLooper!
    private var arView: ARView!
    private var player: AVQueuePlayer!
    private var displayEntity: ModelEntity!
    private var anchorEntity: AnchorEntity!
    private var isActiveSub:Cancellable!
    let coachingOverlay = ARCoachingOverlayView()
    
    @Binding var didTap:Bool
    
    init(didTap:Binding<Bool>) {
        _didTap = didTap
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var request:VNRequest = {
        var handPoseRequest = VNDetectHumanHandPoseRequest(completionHandler: handDetectionCompletionHandler)
        handPoseRequest.maximumHandCount = 1
        return handPoseRequest
    }()
    var focusEntity: FocusEntity!
    var viewWidth:Int = 0
    var viewHeight:Int = 0
    var box:ModelEntity!
    var coordinator: Coordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize ARView
        arView = ARView(frame: view.bounds)
        arView.session.delegate = self
        view.addSubview(arView)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.frameSemantics = [.personSegmentation]
        arView.session.run(config)
        
        // Initialize FocusEntity
        focusEntity = FocusEntity(on: arView, style: .classic(color: .white))
        
        coordinator = Coordinator()
        coordinator.focusEntity = focusEntity
        
        addMonitorEntity()
        coachingOverlay.goal = .verticalPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        coachingOverlay.frame = arView.bounds
        
        arView.addSubview(coachingOverlay)
        
        NotificationCenter.default.addObserver(forName: .placeObject, object: nil, queue: .main) { _ in
            placeObject(in: self.arView, focusEntity: self.focusEntity)
        }
        
        // Additional setup
        viewWidth = Int(arView.bounds.width)
        viewHeight = Int(arView.bounds.height)
        setupObject()
    }
    
    func addMonitorEntity() {
        anchorEntity = AnchorEntity(plane: .vertical)
        displayEntity = ModelEntity(mesh: .generateBox(size: [2.21,0.2,1.24],cornerRadius: 0.02))
        displayEntity.position = [0,0,0.03]
        
        if let videoURL = Bundle.main.url(forResource: "windChimes", withExtension: "mp4") {
            let asset = AVURLAsset(url: videoURL)
            let playerItem = AVPlayerItem(asset: asset)
            player = AVQueuePlayer(playerItem: playerItem)
            videoLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            let videoMaterial = VideoMaterial(avPlayer: player)
            displayEntity.model?.materials = [videoMaterial]
        }
        anchorEntity.addChild(displayEntity)
        
        isActiveSub = arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: anchorEntity, { event in
            if event.isAnchored {
                self.player.play()
            }
        })
        
        arView.scene.addAnchor(anchorEntity)
    }
    
    func showPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        present(picker, animated: true) {
            self.didTap = false
        }
    }
    
    private func setupObject(){}
    
    var recentIndexFingerPoint:CGPoint = .zero
    
    func handDetectionCompletionHandler(request: VNRequest?, error: Error?) {
        guard let observation = request?.results?.first as? VNHumanHandPoseObservation else { return }
        guard let indexFingerTip = try? observation.recognizedPoints(.all)[.indexTip],
              indexFingerTip.confidence > 0.9 else {return}
        
        let normalizedIndexPoint = VNImagePointForNormalizedPoint(CGPoint(x: indexFingerTip.location.y, y: indexFingerTip.location.x), viewWidth,  viewHeight)
        
        let hitTestResults = arView.hitTest(normalizedIndexPoint, types: [.existingPlaneUsingExtent, .featurePoint])
        if let result = hitTestResults.first {
            let hitPosition = simd_make_float3(result.worldTransform.columns.3)
            
            if let entity = placedEntity {
                if distance(entity.position(relativeTo: nil), hitPosition) < 0.05 {
                    // Drawing mechanism
                    DispatchQueue.main.async {
                        self.drawEntity(at: hitPosition, entity:entity)
                    }
                }
            }
        }
        
        recentIndexFingerPoint = normalizedIndexPoint
    }
    
    func drawEntity(at indexPoint: SIMD3<Float>, entity: ModelEntity) {
        // Generate a sphere mesh and material
        let sphere = MeshResource.generateSphere(radius: 0.01)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        
        // Calculate the position to place the sphere on top of the entity
        let entityBounds = entity.visualBounds(relativeTo: nil)
        let sphereHeight = sphereEntity.visualBounds(relativeTo: nil).extents.y
        
        // Calculate the correct position to place the sphere on top of the horizontal canvas
        var position = indexPoint
        position.z += entityBounds.extents.z / 2 + sphereHeight / 2 // Adjust the z position to place the sphere on top of the canvas
        
        // Set the position of the sphere
        sphereEntity.position = position
        
        // Create an anchor to hold the sphere entity
        let anchorEntity = AnchorEntity(world: sphereEntity.position)
        anchorEntity.addChild(sphereEntity)
        
        // Add the anchor entity to the AR scene
        arView.scene.addAnchor(anchorEntity)
        
        print("Sphere successfully added to the scene at position: \(position)")
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let handler = VNImageRequestHandler(cvPixelBuffer:pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([(self?.request)!])
                
            } catch let error {
                print(error)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL]  as? URL {
            let asset = AVURLAsset(url: videoURL)
            let playerItem = AVPlayerItem(asset: asset)
            player = AVQueuePlayer(playerItem: playerItem)
            videoLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            let videoMaterial = VideoMaterial(avPlayer: player)
            displayEntity.model?.materials = [videoMaterial]
            player.play()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


func placeObject(in arView: ARView, focusEntity: FocusEntity?) {
    guard let focusEntity = focusEntity else { return }
    
    do {
        let modelEntity = try ModelEntity.loadModel(named: "Clipboard")
        
        
        let focusTransform = focusEntity.transformMatrix(relativeTo: nil)
        let correctedTransform = focusTransform * float4x4(simd_quatf(angle: .pi / 2 * -1, axis: [1, 0, 0]))
        
        let anchorEntity = AnchorEntity(world: correctedTransform)
        anchorEntity.addChild(modelEntity)
        
        arView.scene.addAnchor(anchorEntity)
        
        // Assign the placed entity to the global variable
        placedEntity = modelEntity
        
    } catch {
        print("Failed to load model: \(error)")
    }
}

extension Notification.Name {
    static let placeObject = Notification.Name("placeObject")
}


