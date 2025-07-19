//
//  RegularButton.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct RegularButton: View {
    var Label: String
    var action: (() -> Void)?
    var color: String
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack {
                Text(Label)
                    .foregroundColor(Color(color))
                    .font(.system(size: 12))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color(color).opacity(0.3), lineWidth: 1))
            }
        }
    }
}
