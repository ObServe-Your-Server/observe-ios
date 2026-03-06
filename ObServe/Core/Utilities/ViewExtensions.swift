//
//  ViewExtension.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI

extension View {
    /// Applies an inner shadow effect to the view
    /// - Parameters:
    ///   - color: The color of the inner shadow
    ///   - blur: The blur radius of the shadow
    ///   - spread: The spread of the shadow (negative values create tighter shadows)
    ///   - offsetX: Horizontal offset of the shadow
    ///   - offsetY: Vertical offset of the shadow
    ///   - opacity: The opacity of the shadow color
    ///   - cornerRadius: The corner radius of the shape (default: 0)
    func innerShadow(
        color: Color = .black,
        blur: CGFloat = 10,
        spread: CGFloat = 0,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        opacity: Double = 0.5,
        cornerRadius: CGFloat = 0
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color.opacity(opacity))
                        .frame(
                            width: width + spread * 2,
                            height: height + spread * 2
                        )
                        .blur(radius: blur)
                        .offset(x: offsetX - spread, y: offsetY - spread)
                        .mask(
                            ZStack {
                                Rectangle()
                                    .fill(Color.black)

                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.white)
                                    .frame(
                                        width: width + spread * 2,
                                        height: height + spread * 2
                                    )
                                    .blur(radius: blur)
                                    .offset(x: offsetX - spread, y: offsetY - spread)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    InnerShadowPreview()
}

struct InnerShadowPreview: View {
    @State private var blur: CGFloat = 25
    @State private var spread: CGFloat = -2
    @State private var opacity: Double = 0.1

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Button(action: {
                    }
                ) {
                    ZStack {
                        Text("Test")
                            .foregroundColor(Color.blue)
                            .font(.system(size: 12))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 120)
                            .overlay(RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1))
                    }
                    .innerShadow(
                        color: Color.blue,
                        blur: blur,
                        spread: spread,
                        offsetX: 0,
                        offsetY: 0,
                        opacity: opacity
                    )
                }
            }
            .frame(height: 200)

            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Blur: \(String(format: "%.1f", blur))")
                        .foregroundColor(.white)
                        .font(.caption)
                    Slider(value: $blur, in: 0...50)
                        .tint(.blue)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Spread: \(String(format: "%.1f", spread))")
                        .foregroundColor(.white)
                        .font(.caption)
                    Slider(value: $spread, in: -20...20)
                        .tint(.blue)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Opacity: \(String(format: "%.2f", opacity))")
                        .foregroundColor(.white)
                        .font(.caption)
                    Slider(value: $opacity, in: 0...1)
                        .tint(.blue)
                }
            }
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(.all)
    }
}
