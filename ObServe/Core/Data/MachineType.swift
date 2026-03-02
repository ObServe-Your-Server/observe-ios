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
    case singleBoard = "SINGLE BOARD"
    case cube = "CUBE"
    case tower = "TOWER"
    case vm = "VM"
    case laptop = "LAPTOP"

    var icon: String {
        switch self {
        case .server: return "server.rack"
        case .singleBoard: return "cpu"
        case .cube: return "cube"
        case .tower: return "desktopcomputer"
        case .vm: return "square.3.layers.3d"
        case .laptop: return "laptopcomputer"
        }
    }

    func imageName(isSelected: Bool) -> String {
        let suffix = isSelected ? "_on" : "_off"
        switch self {
        case .server: return "server" + suffix
        case .singleBoard: return "singleBoard" + suffix
        case .cube: return "cube" + suffix
        case .tower: return "tower" + suffix
        case .vm: return "vm" + suffix
        case .laptop: return "laptop" + suffix
        }
    }

    /// Map to the backend MachineType enum values
    var backendType: String {
        switch self {
        case .server: return "SERVER"
        case .singleBoard: return "DESKTOP"
        case .cube: return "DESKTOP"
        case .tower: return "DESKTOP"
        case .vm: return "VIRTUAL_MACHINE"
        case .laptop: return "LAPTOP"
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
