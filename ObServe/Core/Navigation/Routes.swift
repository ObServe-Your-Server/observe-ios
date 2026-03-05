//
//  Routes.swift
//  ObServe
//
//  Top-level page enum used for state-driven crossfade navigation.
//

import Foundation

enum ActivePage: Equatable {
    case dashboard
    case settings
    case account
    case server
    case alerts
}
