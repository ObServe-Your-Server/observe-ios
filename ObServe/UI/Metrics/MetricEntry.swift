//
//  MetricEntry.swift
//  ObServe
//
//  Created by Daniel Schatz on 03.08.25.
//
import Foundation

struct MetricEntry: Identifiable {
    let id = UUID()
    let timestamp: Double
    let value: Double
}
