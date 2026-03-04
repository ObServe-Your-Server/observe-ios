//
//  MachineType.swift
//  ObServe
//
//  Machine type enum used across the app for server categorization.
//  Shared between main app and widget targets.
//

import Foundation

enum MachineType: String, CaseIterable {
    case server = "SERVER"
    case singleBoard = "SINGLE_BOARD"
    case cube = "CUBE"
    case desktop = "DESKTOP"
    case vm = "VM"
    case container = "CONTAINER"

    /// Cases shown in the UI type picker (excludes laptop which is backend-only)
    static var uiCases: [MachineType] {
        [.server, .singleBoard, .cube, .desktop, .vm, .container]
    }

    var icon: String {
        switch self {
        case .server: return "server.rack"
        case .singleBoard: return "cpu"
        case .cube: return "cube"
        case .desktop: return "desktopcomputer"
        case .vm: return "square.3.layers.3d"
        case .container: return "shippingbox"
        }
    }

    func imageName(isSelected: Bool) -> String {
        let suffix = isSelected ? "_on" : "_off"
        switch self {
        case .server: return "server" + suffix
        case .singleBoard: return "singleBoard" + suffix
        case .cube: return "cube" + suffix
        case .desktop: return "desktop" + suffix
        case .vm: return "vm" + suffix
        case .container: return "container" + suffix
        }
    }

    /// Initialize from string (case-insensitive)
    init?(fromString string: String) {
        if let match = MachineType.allCases.first(where: {
            $0.rawValue.uppercased() == string.uppercased()
        }) {
            self = match
        } else {
            return nil
        }
    }
}
