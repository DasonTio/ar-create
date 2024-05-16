//
//  ARViewModel.swift
//  ar-test
//
//  Created by Dason Tiovino on 16/05/24.
//

import SwiftUI
import RealityKit
import Combine
import ARKit

class ARViewModel: ObservableObject {
    let arView = ARView(frame: .zero)
    var anchorEntity: AnchorEntity?
    var cancellables = Set<AnyCancellable>()

    init() {
        setupARView()
    }

    private func setupARView() {
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        addAnchorEntity()
    }

    private func addAnchorEntity() {
        anchorEntity = AnchorEntity(plane: .horizontal, minimumBounds: SIMD2(0.0001, 0.0001))
        let box = ModelEntity(mesh: .generateBox(size: 0.1))
        anchorEntity?.addChild(box)
        if let anchorEntity = anchorEntity {
            arView.scene.addAnchor(anchorEntity)
        }
    }

    func refreshAnchorEntity() {
        guard let anchorEntity = anchorEntity else { return }

        // Remove the old anchor entity
        arView.scene.removeAnchor(anchorEntity)

        // Create and add a new anchor entity
        let newAnchorEntity = AnchorEntity(plane: .horizontal)
        let box = ModelEntity(mesh: .generateBox(size: 0.1))
        newAnchorEntity.addChild(box)
        arView.scene.addAnchor(newAnchorEntity)

        // Update the reference
        self.anchorEntity = newAnchorEntity
    }
}
