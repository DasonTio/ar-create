//
//  ARViewContainer.swift
//  ar-test
//
//  Created by Dason Tiovino on 20/05/24.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set up AR session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .anyPlane
        coachingOverlay.activatesAutomatically = true
        arView.addSubview(coachingOverlay)
        
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let arView = parent.arView else { return }
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let cursorEntity = self.createCursorEntity()
                    cursorEntity.transform = Transform(matrix: planeAnchor.transform)
                    arView.scene.addAnchor(cursorEntity)
                }
            }
        }
        
        func createCursorEntity() -> AnchorEntity {
            let cursorMesh = MeshResource.generateSphere(radius: 0.01)
            let cursorMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let cursorModel = ModelEntity(mesh: cursorMesh, materials: [cursorMaterial])
            
            let cursorAnchor = AnchorEntity()
            cursorAnchor.addChild(cursorModel)
            
            return cursorAnchor
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let arView = parent.arView else { return }
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    if let cursorEntity = arView.scene.anchors.first(where: { $0 is AnchorEntity }) as? AnchorEntity {
                        cursorEntity.transform = Transform(matrix: planeAnchor.transform)
                        // Additional rotation adjustments can be applied here if needed
                    }
                }
            }
        }
    }
    
    var arView: ARView?
}
    