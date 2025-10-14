//
//  ServerModuleItem.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//
import SwiftData
import SwiftUI

@Model
class ServerModuleItem {
    var id: UUID = UUID()
    var name: String = ""
    var ip: String = ""
    var port: String = ""
    var apiKey: String = ""
    var type: String = ""
    var lastConnected: Date?
    var isConnected: Bool = false
    var isHealthy: Bool = false

    init(name: String, ip: String, port: String, apiKey: String, type: String) {
        self.name = name
        self.ip = ip
        self.port = port
        self.apiKey = apiKey
        self.type = type
    }
}
