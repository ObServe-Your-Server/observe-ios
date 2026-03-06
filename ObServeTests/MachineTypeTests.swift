//
//  MachineTypeTests.swift
//  ObServeTests
//
//  Tests for MachineType enum: rawValues, icons, imageName generation,
//  uiCases, and init?(fromString:) factory.
//

import Testing
@testable import ObServe

struct MachineTypeTests {

    // MARK: - Raw Values

    @Test func allCasesHaveExpectedRawValues() {
        #expect(MachineType.server.rawValue == "SERVER")
        #expect(MachineType.singleBoard.rawValue == "SINGLE_BOARD")
        #expect(MachineType.cube.rawValue == "CUBE")
        #expect(MachineType.desktop.rawValue == "DESKTOP")
        #expect(MachineType.vm.rawValue == "VM")
        #expect(MachineType.container.rawValue == "CONTAINER")
        #expect(MachineType.laptop.rawValue == "LAPTOP")
    }

    @Test func allCasesCount() {
        #expect(MachineType.allCases.count == 7)
    }

    @Test func uiCasesExcludesLaptop() {
        #expect(MachineType.uiCases.count == 6)
        #expect(!MachineType.uiCases.contains(.laptop))
    }

    // MARK: - Icon Names

    @Test func sfSymbolIconNames() {
        #expect(MachineType.server.icon == "server.rack")
        #expect(MachineType.singleBoard.icon == "cpu")
        #expect(MachineType.cube.icon == "cube")
        #expect(MachineType.desktop.icon == "desktopcomputer")
        #expect(MachineType.vm.icon == "square.3.layers.3d")
        #expect(MachineType.container.icon == "shippingbox")
        #expect(MachineType.laptop.icon == "laptopcomputer")
    }

    // MARK: - Image Name Generation

    @Test func imageNameSelected() {
        #expect(MachineType.server.imageName(isSelected: true) == "server_on")
        #expect(MachineType.desktop.imageName(isSelected: true) == "desktop_on")
        #expect(MachineType.vm.imageName(isSelected: true) == "vm_on")
        #expect(MachineType.container.imageName(isSelected: true) == "container_on")
    }

    @Test func imageNameUnselected() {
        #expect(MachineType.server.imageName(isSelected: false) == "server_off")
        #expect(MachineType.desktop.imageName(isSelected: false) == "desktop_off")
        #expect(MachineType.vm.imageName(isSelected: false) == "vm_off")
        #expect(MachineType.container.imageName(isSelected: false) == "container_off")
    }

    @Test func imageNameAllCasesBothStates() {
        for machineType in MachineType.allCases {
            let on = machineType.imageName(isSelected: true)
            let off = machineType.imageName(isSelected: false)
            #expect(on.hasSuffix("_on"))
            #expect(off.hasSuffix("_off"))
            let baseOn = on.replacingOccurrences(of: "_on", with: "")
            let baseOff = off.replacingOccurrences(of: "_off", with: "")
            #expect(baseOn == baseOff)
        }
    }

    // MARK: - init?(fromString:)

    @Test func initFromStringExactMatch() {
        #expect(MachineType(fromString: "SERVER") == .server)
        #expect(MachineType(fromString: "SINGLE_BOARD") == .singleBoard)
        #expect(MachineType(fromString: "CUBE") == .cube)
        #expect(MachineType(fromString: "DESKTOP") == .desktop)
        #expect(MachineType(fromString: "VM") == .vm)
        #expect(MachineType(fromString: "CONTAINER") == .container)
        #expect(MachineType(fromString: "LAPTOP") == .laptop)
    }

    @Test func initFromStringCaseInsensitive() {
        #expect(MachineType(fromString: "server") == .server)
        #expect(MachineType(fromString: "Server") == .server)
        #expect(MachineType(fromString: "single_board") == .singleBoard)
        #expect(MachineType(fromString: "container") == .container)
    }

    @Test func initFromStringInvalidReturnsNil() {
        #expect(MachineType(fromString: "") == nil)
        #expect(MachineType(fromString: "SINGLE BOARD") == nil)
        #expect(MachineType(fromString: "TOWER") == nil)
        #expect(MachineType(fromString: "VIRTUAL_MACHINE") == nil)
        #expect(MachineType(fromString: "nonexistent") == nil)
    }
}
