//
//  ServerModuleItem.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//
import SwiftData

@Model
class ServerModuleItem {
    var name: String
    var ip: String
    var port: String

    init(name: String, ip: String, port: String) {
        self.name = name
        self.ip = ip
        self.port = port
    }
}
