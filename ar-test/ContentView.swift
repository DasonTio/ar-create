//
//  ContentView.swift
//  ar-test
//
//  Created by Dason Tiovino on 27/05/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView: View {
    
    @State var didTap = false

    var body: some View {
        ZStack {
            ARViewContainer(didTap: $didTap).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                HStack{
                    Button(action: {
                        NotificationCenter.default.post(name: .placeObject, object: nil)
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                            .padding()
                    }
                    
                    Button(action: didTapButton){
                        Image(systemName: "photo")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                            .padding()
                    }
                }

                
            }
        }
    }
    
    func didTapButton() {
        didTap = true
    }
}

    

struct ARViewContainer: UIViewControllerRepresentable {
    @Binding var didTap:Bool
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        if didTap {
            uiViewController.showPicker()
        }
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewContainer>) -> ViewController {
        let viewController = ViewController(didTap: $didTap)
        return viewController
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
