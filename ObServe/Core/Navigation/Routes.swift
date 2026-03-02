//
//  Routes.swift
//  ObServe
//
//  Navigation route types used for tab/screen navigation.
//

import Foundation

struct SettingsRoute: Identifiable, Hashable {
    let id = UUID()
}

struct AccountRoute: Identifiable, Hashable {
    let id = UUID()
}

struct ServerRoute: Identifiable, Hashable {
    let id = UUID()
}

struct AlertsRoute: Identifiable, Hashable {
    let id = UUID()
}
