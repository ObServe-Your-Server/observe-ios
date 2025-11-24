//
//  PercentLabel.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

struct PercentLabel: View {
    var value: Double
    var maximum: Double = 100.0
    
    var body: some View {
            let percent = (maximum == 0) ? 0 : min(max(value / maximum, 0), 1)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.4))
                    Rectangle()
                        .frame(width: geometry.size.width * percent, height: 6)
                        .foregroundColor(Color("ObServeGray"))
                    Rectangle()
                        .frame(width: 1, height: 6)
                        .foregroundColor(Color.gray.opacity(0.4))
                        .position(x: geometry.size.width, y: geometry.size.height / 2)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 4)
        }
}
