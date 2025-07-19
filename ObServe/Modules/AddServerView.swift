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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NEW MACHINE")
                    .foregroundColor(.white)
                Spacer()
                RegularButton(Label: "CANCEL", action: onCancel, color: "Gray")
                    .frame(maxWidth: 100)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("NAME")
                    .foregroundColor(.gray)
                    .font(.system(size: 9))
                TextField("SERVER 1", text: $name)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(.gray).opacity(0.3), lineWidth: 1))
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP v4")
                        .foregroundColor(.gray)
                        .font(.system(size: 9))
                    TextField("00.000.000.00", text: $ip)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color(.gray).opacity(0.3), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORT")
                        .foregroundColor(.gray)
                        .font(.system(size: 9))
                    TextField("42000", text: $port)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color(.gray).opacity(0.3), lineWidth: 1))
                }
            }
            HStack {
                Image(systemName: "exclamationmark")
                    .foregroundColor(.white)
                Text("connection only possible if the software is correctly setup on desktop")
                    .foregroundColor(.gray).font(.system(size: 10))
                Spacer()
                RegularButton(Label: "CONNECT", action: {
                    let newServer = ServerModuleItem(name: name.isEmpty ? "SERVER" : name, ip: ip.isEmpty ? "00.000.000.00" : ip, port: port.isEmpty ? "42000" : port)
                    onConnect(newServer)
                }, color: "Blue").frame(maxWidth: 100)
            }
        }
        .padding(20)
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
            .frame(width: 360)
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
