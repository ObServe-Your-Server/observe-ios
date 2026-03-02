//
//  MachineTypeTests.swift
//  ObServeTests
//
//  Tests for MachineType enum: rawValues, icons, backendType mapping,
//  imageName generation, and init?(fromString:) factory.
//

import Testing
@testable import ObServe

struct MachineTypeTests {

    // MARK: - Raw Values

    @Test func allCasesHaveExpectedRawValues() {
        #expect(MachineType.server.rawValue == "SERVER")
        #expect(MachineType.singleBoard.rawValue == "SINGLE BOARD")
        #expect(MachineType.cube.rawValue == "CUBE")
        #expect(MachineType.tower.rawValue == "TOWER")
        #expect(MachineType.vm.rawValue == "VM")
        #expect(MachineType.laptop.rawValue == "LAPTOP")
    }

    @Test func allCasesCount() {
        #expect(MachineType.allCases.count == 6)
    }

    // MARK: - Backend Type Mapping

    @Test func backendTypeMappings() {
        #expect(MachineType.server.backendType == "SERVER")
        #expect(MachineType.singleBoard.backendType == "DESKTOP")
        #expect(MachineType.cube.backendType == "DESKTOP")
        #expect(MachineType.tower.backendType == "DESKTOP")
        #expect(MachineType.vm.backendType == "VIRTUAL_MACHINE")
        #expect(MachineType.laptop.backendType == "LAPTOP")
    }

    // MARK: - Icon Names

    @Test func sfSymbolIconNames() {
        #expect(MachineType.server.icon == "server.rack")
        #expect(MachineType.singleBoard.icon == "cpu")
        #expect(MachineType.cube.icon == "cube")
        #expect(MachineType.tower.icon == "desktopcomputer")
        #expect(MachineType.vm.icon == "square.3.layers.3d")
        #expect(MachineType.laptop.icon == "laptopcomputer")
    }

    // MARK: - Image Name Generation

    @Test func imageNameSelected() {
        #expect(MachineType.server.imageName(isSelected: true) == "server_on")
        #expect(MachineType.laptop.imageName(isSelected: true) == "laptop_on")
        #expect(MachineType.vm.imageName(isSelected: true) == "vm_on")
    }

    @Test func imageNameUnselected() {
        #expect(MachineType.server.imageName(isSelected: false) == "server_off")
        #expect(MachineType.laptop.imageName(isSelected: false) == "laptop_off")
        #expect(MachineType.vm.imageName(isSelected: false) == "vm_off")
    }

    @Test func imageNameAllCasesBothStates() {
        for machineType in MachineType.allCases {
            let on = machineType.imageName(isSelected: true)
            let off = machineType.imageName(isSelected: false)
            #expect(on.hasSuffix("_on"))
            #expect(off.hasSuffix("_off"))
            // The base name should be the same
            let baseOn = on.replacingOccurrences(of: "_on", with: "")
            let baseOff = off.replacingOccurrences(of: "_off", with: "")
            #expect(baseOn == baseOff)
        }
    }

    // MARK: - init?(fromString:)

    @Test func initFromStringExactMatch() {
        #expect(MachineType(fromString: "SERVER") == .server)
        #expect(MachineType(fromString: "CUBE") == .cube)
        #expect(MachineType(fromString: "VM") == .vm)
        #expect(MachineType(fromString: "LAPTOP") == .laptop)
        #expect(MachineType(fromString: "TOWER") == .tower)
        #expect(MachineType(fromString: "SINGLE BOARD") == .singleBoard)
    }

    @Test func initFromStringCaseInsensitive() {
        #expect(MachineType(fromString: "server") == .server)
        #expect(MachineType(fromString: "Server") == .server)
        #expect(MachineType(fromString: "laptop") == .laptop)
        #expect(MachineType(fromString: "single board") == .singleBoard)
    }

    @Test func initFromStringInvalidReturnsNil() {
        #expect(MachineType(fromString: "") == nil)
        #expect(MachineType(fromString: "DESKTOP") == nil)
        #expect(MachineType(fromString: "VIRTUAL_MACHINE") == nil)
        #expect(MachineType(fromString: "nonexistent") == nil)
    }
}
