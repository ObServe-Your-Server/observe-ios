//
//  ServerModuleItem.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//
import SwiftUI

struct ServerModuleItem: Identifiable {
    let id = UUID()
    let name: String
    let ip: String
    let port: String
    let mac: String
}
