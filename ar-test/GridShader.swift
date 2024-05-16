import UIKit

struct GridTexture {
    static func generateGridImage(size: CGSize, gridSize: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(1.0)
            
            for x in stride(from: 0, to: size.width, by: gridSize) {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            for y in stride(from: 0, to: size.height, by: gridSize) {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            context.strokePath()
        }
    }
}
