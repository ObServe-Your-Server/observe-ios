//
//  APIModelsTests.swift
//  ObServeTests
//
//  Tests for API model encoding/decoding (Codable conformance).
//

import Testing
import Foundation
@testable import ObServe

struct APIModelsTests {

    // MARK: - MachineMetricResponse Decoding

    @Test func decodeMetricResponseFullPayload() throws {
        let json = """
        {
            "uuid": "550e8400-e29b-41d4-a716-446655440000",
            "capturedAt": "2025-07-20T10:30:00Z",
            "cpuUsage": 45.5,
            "cpuTemperature": 62.3,
            "memUsed": 8589934592,
            "memTotal": 17179869184,
            "disks": [
                {"name": "sda1", "total": 500107862016, "used": 250053931008}
            ],
            "netBytesIn": 1048576,
            "netBytesOut": 524288,
            "uptime": 86400,
            "speedtest": {
                "pingMs": 12.5,
                "uploadMbps": 50.0,
                "downloadMbps": 100.0
            }
        }
        """
        let data = json.data(using: .utf8)!
        let metric = try JSONDecoder().decode(MachineMetricResponse.self, from: data)

        #expect(metric.uuid == "550e8400-e29b-41d4-a716-446655440000")
        #expect(metric.capturedAt == "2025-07-20T10:30:00Z")
        #expect(metric.cpuUsage == 45.5)
        #expect(metric.cpuTemperature == 62.3)
        #expect(metric.memUsed == 8589934592)
        #expect(metric.memTotal == 17179869184)
        #expect(metric.disks?.count == 1)
        #expect(metric.disks?.first?.name == "sda1")
        #expect(metric.netBytesIn == 1048576)
        #expect(metric.netBytesOut == 524288)
        #expect(metric.uptime == 86400)
        #expect(metric.speedtest?.pingMs == 12.5)
        #expect(metric.speedtest?.uploadMbps == 50.0)
        #expect(metric.speedtest?.downloadMbps == 100.0)
    }

    @Test func decodeMetricResponseMinimalPayload() throws {
        let json = """
        {
            "uuid": "test-uuid",
            "capturedAt": "2025-07-20T10:30:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let metric = try JSONDecoder().decode(MachineMetricResponse.self, from: data)

        #expect(metric.uuid == "test-uuid")
        #expect(metric.cpuUsage == nil)
        #expect(metric.cpuTemperature == nil)
        #expect(metric.memUsed == nil)
        #expect(metric.memTotal == nil)
        #expect(metric.disks == nil)
        #expect(metric.netBytesIn == nil)
        #expect(metric.netBytesOut == nil)
        #expect(metric.uptime == nil)
        #expect(metric.speedtest == nil)
    }

    // MARK: - MachineEntityResponse Decoding

    @Test func decodeMachineEntityFullPayload() throws {
        let json = """
        {
            "uuid": "abc-123",
            "ownerId": "owner-456",
            "type": "SERVER",
            "name": "My Server",
            "description": "A test server",
            "location": "Berlin",
            "apiKey": "key-789",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-07-20T10:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let machine = try JSONDecoder().decode(MachineEntityResponse.self, from: data)

        #expect(machine.uuid == "abc-123")
        #expect(machine.ownerId == "owner-456")
        #expect(machine.type == "SERVER")
        #expect(machine.name == "My Server")
        #expect(machine.description == "A test server")
        #expect(machine.location == "Berlin")
        #expect(machine.apiKey == "key-789")
        #expect(machine.createdAt == "2025-01-01T00:00:00Z")
        #expect(machine.updatedAt == "2025-07-20T10:00:00Z")
    }

    @Test func decodeMachineEntityMinimalPayload() throws {
        let json = """
        {"uuid": "minimal-id"}
        """
        let data = json.data(using: .utf8)!
        let machine = try JSONDecoder().decode(MachineEntityResponse.self, from: data)

        #expect(machine.uuid == "minimal-id")
        #expect(machine.ownerId == nil)
        #expect(machine.type == nil)
        #expect(machine.name == nil)
        #expect(machine.apiKey == nil)
    }

    // MARK: - CreateMachineRequest Encoding

    @Test func encodeCreateMachineRequest() throws {
        let request = CreateMachineRequest(
            type: "SERVER",
            name: "Test Server",
            description: "A description",
            location: "Berlin"
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["type"] as? String == "SERVER")
        #expect(dict["name"] as? String == "Test Server")
        #expect(dict["description"] as? String == "A description")
        #expect(dict["location"] as? String == "Berlin")
    }

    @Test func encodeCreateMachineRequestNilOptionals() throws {
        let request = CreateMachineRequest(
            type: "LAPTOP",
            name: "My Laptop",
            description: nil,
            location: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["type"] as? String == "LAPTOP")
        #expect(dict["name"] as? String == "My Laptop")
        // nil optionals should not be present in encoded output
        #expect(dict["description"] == nil || dict["description"] is NSNull)
    }

    // MARK: - UpdateMachineRequest Encoding

    @Test func encodeUpdateMachineRequestPartialUpdate() throws {
        let request = UpdateMachineRequest(
            type: nil,
            name: "New Name",
            description: nil,
            location: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["name"] as? String == "New Name")
    }

    // MARK: - DiskPayloadResponse Decoding

    @Test func decodeDiskPayload() throws {
        let json = """
        {"name": "sda1", "total": 1000000000000, "used": 500000000000}
        """
        let data = json.data(using: .utf8)!
        let disk = try JSONDecoder().decode(DiskPayloadResponse.self, from: data)

        #expect(disk.name == "sda1")
        #expect(disk.total == 1000000000000)
        #expect(disk.used == 500000000000)
    }

    @Test func decodeDiskPayloadWithNulls() throws {
        let json = """
        {"name": null, "total": null, "used": null}
        """
        let data = json.data(using: .utf8)!
        let disk = try JSONDecoder().decode(DiskPayloadResponse.self, from: data)

        #expect(disk.name == nil)
        #expect(disk.total == nil)
        #expect(disk.used == nil)
    }

    // MARK: - SpeedtestPayloadResponse Decoding

    @Test func decodeSpeedtestPayload() throws {
        let json = """
        {"pingMs": 5.2, "uploadMbps": 100.5, "downloadMbps": 250.7}
        """
        let data = json.data(using: .utf8)!
        let speedtest = try JSONDecoder().decode(SpeedtestPayloadResponse.self, from: data)

        #expect(speedtest.pingMs == 5.2)
        #expect(speedtest.uploadMbps == 100.5)
        #expect(speedtest.downloadMbps == 250.7)
    }
}
