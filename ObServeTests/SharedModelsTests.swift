//
//  SharedModelsTests.swift
//  ObServeTests
//
//  Tests for SharedModels: Codable round-trips, computed properties, MetricType.
//

import Testing
import Foundation
@testable import ObServe

struct SharedModelsTests {

    // MARK: - SharedServer Codable

    @Test func sharedServerRoundTrip() throws {
        let id = UUID()
        let machineUUID = UUID()
        let date = Date(timeIntervalSince1970: 1700000000)
        let original = SharedServer(
            id: id,
            machineUUID: machineUUID,
            name: "Test Server",
            type: "SERVER",
            isConnected: true,
            isHealthy: true,
            lastConnected: date,
            uptime: 3600
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharedServer.self, from: data)

        #expect(decoded.id == id)
        #expect(decoded.machineUUID == machineUUID)
        #expect(decoded.name == "Test Server")
        #expect(decoded.type == "SERVER")
        #expect(decoded.isConnected == true)
        #expect(decoded.isHealthy == true)
        #expect(decoded.uptime == 3600)
    }

    @Test func sharedServerDefaultType() {
        let server = SharedServer(
            id: UUID(),
            machineUUID: UUID(),
            name: "No Type",
            isConnected: false,
            isHealthy: false
        )
        #expect(server.type == "")
        #expect(server.lastConnected == nil)
        #expect(server.uptime == nil)
    }

    // MARK: - SharedMetricData Codable

    @Test func sharedMetricDataRoundTrip() throws {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let original = SharedMetricData(
            serverId: id,
            metricType: "CPU",
            value: 45.5,
            timestamp: timestamp,
            history: [10.0, 20.0, 30.0, 45.5]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharedMetricData.self, from: data)

        #expect(decoded.serverId == id)
        #expect(decoded.metricType == "CPU")
        #expect(decoded.value == 45.5)
        #expect(decoded.history == [10.0, 20.0, 30.0, 45.5])
    }

    @Test func sharedMetricDataDefaultHistory() {
        let metric = SharedMetricData(
            serverId: UUID(),
            metricType: "RAM",
            value: 80.0,
            timestamp: Date()
        )
        #expect(metric.history.isEmpty)
    }

    // MARK: - SharedMetricData.isFresh

    @Test func metricDataIsFreshWhenRecent() {
        let metric = SharedMetricData(
            serverId: UUID(),
            metricType: "CPU",
            value: 50.0,
            timestamp: Date() // just now
        )
        #expect(metric.isFresh == true)
    }

    @Test func metricDataIsStaleWhenOld() {
        let metric = SharedMetricData(
            serverId: UUID(),
            metricType: "CPU",
            value: 50.0,
            timestamp: Date().addingTimeInterval(-300) // 5 minutes ago
        )
        #expect(metric.isFresh == false)
    }

    @Test func metricDataIsFreshBoundary() {
        // 119 seconds ago should still be fresh (< 120)
        let metric = SharedMetricData(
            serverId: UUID(),
            metricType: "CPU",
            value: 50.0,
            timestamp: Date().addingTimeInterval(-119)
        )
        #expect(metric.isFresh == true)
    }

    // MARK: - SharedMetricData.ageInSeconds

    @Test func metricDataAgeInSeconds() {
        let twoMinutesAgo = Date().addingTimeInterval(-120)
        let metric = SharedMetricData(
            serverId: UUID(),
            metricType: "RAM",
            value: 70.0,
            timestamp: twoMinutesAgo
        )
        // Allow 1 second tolerance for test execution time
        #expect(metric.ageInSeconds >= 119)
        #expect(metric.ageInSeconds <= 121)
    }

    // MARK: - MetricType

    @Test func metricTypeRawValues() {
        #expect(MetricType.cpu.rawValue == "CPU")
        #expect(MetricType.ram.rawValue == "RAM")
        #expect(MetricType.networkIn.rawValue == "Network In")
        #expect(MetricType.networkOut.rawValue == "Network Out")
        #expect(MetricType.storage.rawValue == "Storage")
        #expect(MetricType.cpuTemperature.rawValue == "CPU Temp")
    }

    @Test func metricTypeDisplayName() {
        for type in MetricType.allCases {
            #expect(type.displayName == type.rawValue)
        }
    }

    @Test func metricTypeAllCasesCount() {
        #expect(MetricType.allCases.count == 6)
    }

    @Test func metricTypeCodableRoundTrip() throws {
        for type in MetricType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(MetricType.self, from: data)
            #expect(decoded == type)
        }
    }
}
