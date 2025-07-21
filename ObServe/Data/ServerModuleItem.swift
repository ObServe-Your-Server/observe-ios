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
    var name: String
    var ip: String
    var port: String
    var lastRuntime: Date?

    init(name: String, ip: String, port: String, date: Date?) {
        self.name = name
        self.ip = ip
        self.port = port
        self.lastRuntime = date
    }
}
