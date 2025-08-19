//
//  BurgerMenu.swift
//  ObServe
//
//  Created by Carlo Derouaux on 20.07.25.
//

import SwiftUI

struct BurgerMenu: View {
    var onDismiss: () -> Void
    var onOverView: () -> Void      // ✅ neu
    var onSettings: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .background(.ultraThinMaterial.opacity(0.8))
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                
                // OVERVIEW
                Button {
                    onDismiss()
                    onOverView()
                } label: {
                    Text("OVERVIEW")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }

                Divider().background(Color.gray)

                // SETTINGS
                Button {
                    onDismiss()
                    onSettings()
                } label: {
                    Text("SETTINGS")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white, lineWidth: 1)
            )
            .frame(width: 220)
            .padding(.top, 58)
            .padding(.trailing, 20)
        }
    }
}
