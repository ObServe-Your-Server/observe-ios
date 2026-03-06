//
//  ExpandCornerIndicator.swift
//  ObServe
//

import SwiftUI

private struct BottomRightTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ExpandCornerIndicator: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            BottomRightTriangle()
                .fill(Color(white: 0.45))
            Canvas { context, canvasSize in
                var path1 = Path()
                path1.move(to: CGPoint(x: canvasSize.width * 0.55, y: canvasSize.height * 0.95))
                path1.addLine(to: CGPoint(x: canvasSize.width * 0.95, y: canvasSize.height * 0.55))
                context.stroke(path1, with: .color(.black), lineWidth: 0.75)

                var path2 = Path()
                path2.move(to: CGPoint(x: canvasSize.width * 0.35, y: canvasSize.height * 0.95))
                path2.addLine(to: CGPoint(x: canvasSize.width * 0.95, y: canvasSize.height * 0.35))
                context.stroke(path2, with: .color(.black), lineWidth: 0.75)
            }
        }
        .frame(width: size, height: size)
    }
}
