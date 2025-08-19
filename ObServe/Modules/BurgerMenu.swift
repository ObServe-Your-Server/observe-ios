//
//  BurgerMenu.swift
//  ObServe
//
//  Created by Carlo Derouaux on 20.07.25.
//

import SwiftUI

struct BurgerMenu: View {
    var onDismiss: () -> Void
    var onOverView: () -> Void
    var onSettings: () -> Void

    @State private var showPanel = false

    var body: some View {
        ZStack(alignment: .topTrailing) {

            Color.black
                .opacity(showPanel ? 0.6 : 0.0)
                .ignoresSafeArea()
                .onTapGesture { dismissAnimated() }
                .animation(.easeInOut(duration: 0.18), value: showPanel)

            Button(action: { dismissAnimated() }) {
                VStack(spacing: 7) {
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                }
                .padding(10)
                .frame(width: 40, height: 40)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.top, 8)
            .padding(.trailing, 20)

            if showPanel {
                VStack(spacing: 0) {
                    Button {
                        dismissAnimated {
                            onOverView()
                        }
                    } label: {
                        Text("OVERVIEW")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }

                    Divider().background(Color.gray)

                    Button {
                        dismissAnimated {
                            onSettings()
                        }
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
                .offset(x: showPanel ? 0 : 20, y: showPanel ? 0 : -12)
                .opacity(showPanel ? 1 : 0)
                .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showPanel)
                .transition(.opacity) // falls bedingt entfernt
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                showPanel = true
            }
        }
    }

    // MARK: - Helpers
    private func dismissAnimated(after action: (() -> Void)? = nil) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
            showPanel = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
            action?()
        }
    }
}
