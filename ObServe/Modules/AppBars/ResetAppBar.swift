//
//  ResetAppBar.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI

struct ResetAppBar: View {
    @Binding var contentHasScrolled: Bool
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RESET DATA")
                        .foregroundColor(.white)
                    
                    Button(action: {
                        // später später
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text("U SURE?")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color("ButtonBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                Spacer()

                Button(action: {
                    Haptics.click()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color("ButtonBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(Color.black)

            // Bottom border separator when scrolled
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
                .opacity(contentHasScrolled ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
        }
        .background(Color.black.ignoresSafeArea(edges: .top))
    }
}
