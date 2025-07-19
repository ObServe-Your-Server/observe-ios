//
//  AddServerModule.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

struct AddServerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("NEW MACHINE")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Button("CANCEL") { /* dismiss action */ }
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("NAME")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("SERVER 1", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP v4")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("00.000.000.00", text: .constant(""))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORT")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("0000", text: .constant(""))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("MAC")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("00.00.00.00.00.00", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
            }
            HStack {
                Image(systemName: "exclamationmark")
                    .foregroundColor(.white)
                Text("A connection is only possible if the software is correctly setup on the desktop")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            HStack {
                Spacer()
                Button("CONNECT") { /* connect action */ }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
            }
        }
        .padding(24)
    }
}

struct AddServerOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack {
                AddServerView()
                    .padding(0)
            }
            .frame(width: 360, height: 420)
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}

struct AddServerOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack {
                AddServerView()
                    .padding(0)
            }
            .frame(width: 360, height: 420)
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(radius: 24)
        }
    }
}

#Preview {
    AddServerOverlay(onDismiss: {})
}
