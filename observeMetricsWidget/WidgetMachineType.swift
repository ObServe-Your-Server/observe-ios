//
//  WidgetMachineType.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 24.10.25.
//

import SwiftUI

/// Machine type enum for widget icon display
/// Mirrors the MachineType enum from the main app
enum WidgetMachineType: String, CaseIterable {
    case server = "SERVER"
    case singleBoard = "SINGLE BOARD"
    case cube = "CUBE"
    case tower = "TOWER"
    case vm = "VM"
    case laptop = "LAPTOP"

    /// Get the image name based on online/offline status
    /// - Parameter isOnline: true if server is connected and healthy
    /// - Returns: Image name with _on or _off suffix
    func imageName(isOnline: Bool) -> String {
        let suffix = isOnline ? "_on" : "_off"
        switch self {
        case .server: return "server" + suffix
        case .singleBoard: return "singleBoard" + suffix
        case .cube: return "cube" + suffix
        case .tower: return "tower" + suffix
        case .vm: return "vm" + suffix
        case .laptop: return "laptop" + suffix
        }
    }

    /// Initialize from string (case-insensitive)
    init?(fromString string: String) {
        // Try to find a matching case
        if let match = WidgetMachineType.allCases.first(where: {
            $0.rawValue.uppercased() == string.uppercased()
        }) {
            self = match
        } else {
            return nil
        }
    }
}
