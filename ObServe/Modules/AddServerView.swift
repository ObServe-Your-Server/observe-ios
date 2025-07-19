//
//  AddServerModule.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

struct AddServerView: View {
    var onCancel: () -> Void
    var onConnect: (ServerModuleItem) -> Void
    
    @State private var name = ""
    @State private var ip = ""
    @State private var port = ""
    @State private var mac = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NEW MACHINE")
                    .foregroundColor(.white)
                Spacer()
                Button("CANCEL") { onCancel() }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("NAME")
                    .foregroundColor(.gray)
                TextField("SERVER 1", text: $name)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP v4")
                        .foregroundColor(.gray)
                    TextField("00.000.000.00", text: $ip)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORT")
                        .foregroundColor(.gray)
                    TextField("42000", text: $port)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("MAC")
                    .foregroundColor(.gray)
                TextField("00.00.00.00.00.00", text: $mac)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
            }
            HStack {
                Image(systemName: "exclamationmark")
                    .foregroundColor(.white)
                Text("A connection is only possible if the software is correctly setup on the desktop")
                    .foregroundColor(.gray)
            }
            HStack {
                Spacer()
                Button("CONNECT") {
                                    let newServer = ServerModuleItem(name: name, ip: ip, port: port, mac: mac)
                                    onConnect(newServer)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
            }
        }
        .padding(12)
    }
}

struct AddServerOverlay: View {
    var onDismiss: () -> Void
    var onConnect: (ServerModuleItem) -> Void

    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial.opacity(0.8))
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack {
                            AddServerView(onCancel: onDismiss, onConnect: onConnect)
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

#Preview {
    AddServerOverlay(onDismiss: {}, onConnect: { _ in })
}
