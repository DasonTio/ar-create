//
//  HandInteractionView.swift
//  ar-test
//
//  Created by Dason Tiovino on 27/05/24.
//

import Foundation
import SwiftUI

struct HandInteractionView: View {
    var body: some View {
        HandInteractionARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct HandInteractionARViewContainer: UIViewControllerRepresentable {
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<HandInteractionARViewContainer>) -> ViewController {
        let viewController = ViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<HandInteractionARViewContainer>) {
        
    }
    
    func makeCoordinator() -> HandInteractionARViewContainer.Coordinator {
        return Coordinator()
    }
    
    class Coordinator {
        
    }
}
