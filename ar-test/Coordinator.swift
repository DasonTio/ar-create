//
//  Coordinator.swift
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

class Coordinator {
    var focusEntity: FocusEntity?
    private var initialPanLocation: SIMD3<Float>?
    private var selectedEntity: Entity?

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = sender.view as? ARView else { return }
        let location = sender.location(in: arView)
        let hitTestResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        
        if let firstResult = hitTestResults.first {
            if let entity = arView.entity(at: location) {
                print(arView.entities)
                
                if selectedEntity === entity {
                    // Deselect the entity
                    selectedEntity = nil
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model?.materials = [SimpleMaterial(color: .white, isMetallic: true)]
                    }
                } else {
                    // Select the new entity
                    selectedEntity = entity
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
                    }
                }
            }
        }
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let arView = sender.view as? ARView else { return }
        let translation = sender.translation(in: arView)
        
        if sender.state == .began {
            // Capture the initial position when the pan starts
            let location = sender.location(in: arView)
            let hitTestResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
            if let firstResult = hitTestResults.first, let entity = arView.entity(at: location) {
                initialPanLocation = entity.position(relativeTo: nil)
                selectedEntity = entity
            }
        } else if sender.state == .changed, let selectedEntity = selectedEntity {
            // Update the entity's position based on pan gesture
            guard let initialLocation = initialPanLocation else { return }
            let xTranslation = Float(translation.x) * 0.01
            let yTranslation = Float(-translation.y) * 0.01
            
            var newLocation = initialLocation
            newLocation.x += xTranslation
            newLocation.y += yTranslation
            
            selectedEntity.setPosition(newLocation, relativeTo: nil)
        } else if sender.state == .ended {
            // Reset the initial pan location
            initialPanLocation = nil
        }
    }
}
