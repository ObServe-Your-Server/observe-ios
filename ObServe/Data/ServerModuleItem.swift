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
    var type: String = ""
    var lastRuntime: Date?
    var isOn: Bool = false
    var runtimeDuration: TimeInterval?

    init(name: String, ip: String, port: String, type: String) {
        self.name = name
        self.ip = ip
        self.port = port
        self.type = type
    }
}
