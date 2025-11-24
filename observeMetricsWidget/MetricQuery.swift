//
//  MetricQuery.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 21.10.25.
//

import Foundation
import AppIntents

/// Available metric types for widget
enum WidgetMetricType: String, CaseIterable {
    case cpu = "CPU"
    case ram = "RAM"
    case storage = "Storage"

    var displayName: String {
        return self.rawValue
    }
}

/// Entity representing a metric type for widget configuration
struct MetricEntity: AppEntity, Identifiable {
    let id: String
    let displayString: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Metric"

    static var defaultQuery = MetricQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }
}

/// Query to fetch available metric types
struct MetricQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [MetricEntity] {
        return WidgetMetricType.allCases
            .filter { identifiers.contains($0.rawValue) }
            .map { MetricEntity(id: $0.rawValue, displayString: $0.displayName) }
    }

    func suggestedEntities() async throws -> [MetricEntity] {
        return WidgetMetricType.allCases.map {
            MetricEntity(id: $0.rawValue, displayString: $0.displayName)
        }
    }

    func defaultResult() async -> MetricEntity? {
        return MetricEntity(id: WidgetMetricType.cpu.rawValue, displayString: WidgetMetricType.cpu.displayName)
    }

    func entities(matching string: String) async throws -> [MetricEntity] {
        if string.isEmpty {
            return try await suggestedEntities()
        }

        let lowercasedQuery = string.lowercased()
        return WidgetMetricType.allCases
            .filter { $0.displayName.lowercased().contains(lowercasedQuery) }
            .map { MetricEntity(id: $0.rawValue, displayString: $0.displayName) }
    }
}
