//
//  AppBar.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct AppBar: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("0 MACHINES")
                Button(action: {
                    // Später Später
                }) {
                    Text("SORT: ALL")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color("ButtonBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            Spacer()
            Button(action: {
                // Später Später
            }) {
                VStack(spacing: 7) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 2.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
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
        .padding(.bottom, 5)
        .background(Color.black)
    }
}

#Preview {
    AppBar()
}
