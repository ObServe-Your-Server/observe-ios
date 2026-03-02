//
//  SettingsManager.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import Foundation
import Combine

/// Centralized settings manager for ObServe
/// Persists settings to UserDefaults in App Group for widget access
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // App Group identifier for sharing with widgets
    private let appGroup = "group.com.dev.ObServe"
    private let defaults: UserDefaults

    // MARK: - Setting Keys
    private enum Keys {
        static let preciseDataEnabled = "preciseDataEnabled"
        static let showIconsEnabled = "showIconsEnabled"
        static let safeModeEnabled = "safeModeEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let pollingIntervalSeconds = "pollingIntervalSeconds"
        static let autoConnectOnLaunch = "autoConnectOnLaunch"
    }

    // MARK: - Data Display Settings

    /// When enabled, metrics display with full precision (not rounded)
    @Published var preciseDataEnabled: Bool {
        didSet {
            defaults.set(preciseDataEnabled, forKey: Keys.preciseDataEnabled)
        }
    }

    // MARK: - Interaction Settings

    /// When enabled, critical actions require confirmation dialogs
    @Published var safeModeEnabled: Bool {
        didSet {
            defaults.set(safeModeEnabled, forKey: Keys.safeModeEnabled)
        }
    }

    /// When enabled, haptic feedback triggers on button taps
    @Published var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    /// Automatically connect to all servers when app launches
    @Published var autoConnectOnLaunch: Bool {
        didSet {
            defaults.set(autoConnectOnLaunch, forKey: Keys.autoConnectOnLaunch)
        }
    }

    // MARK: - Performance Settings

    /// How often to fetch new metric data (in seconds)
    /// Valid values: 1, 5, 10, 30, 60
    @Published var pollingIntervalSeconds: Int {
        didSet {
            defaults.set(pollingIntervalSeconds, forKey: Keys.pollingIntervalSeconds)
            defaults.synchronize()  // Force immediate write to disk
        }
    }

    // MARK: - Initialization

    private init() {
        // Initialize UserDefaults with App Group
        if let appGroupDefaults = UserDefaults(suiteName: appGroup) {
            self.defaults = appGroupDefaults
        } else {
            // Fallback to standard UserDefaults if App Group fails
            self.defaults = UserDefaults.standard
            print("Warning: Failed to initialize App Group UserDefaults, using standard")
        }

        // Load saved values or use defaults
        self.preciseDataEnabled = defaults.bool(forKey: Keys.preciseDataEnabled)
        self.safeModeEnabled = defaults.object(forKey: Keys.safeModeEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        self.autoConnectOnLaunch = defaults.bool(forKey: Keys.autoConnectOnLaunch)

        // Polling interval defaults to 5 seconds
        // Use object(forKey:) to properly detect nil (no value) vs actual saved values
        self.pollingIntervalSeconds = defaults.object(forKey: Keys.pollingIntervalSeconds) as? Int ?? 5
    }

    // MARK: - Reset Methods

    /// Reset all settings to default values
    func resetAllSettings() {
        preciseDataEnabled = false
        safeModeEnabled = true
        hapticsEnabled = true
        autoConnectOnLaunch = false
        pollingIntervalSeconds = 5
    }

    /// Get polling interval label for UI display
    func pollingIntervalLabel() -> String {
        switch pollingIntervalSeconds {
        case 1: return "1 second"
        case 5: return "5 seconds"
        case 10: return "10 seconds"
        case 30: return "30 seconds"
        case 60: return "1 minute"
        default: return "\(pollingIntervalSeconds) seconds"
        }
    }

    /// Get all valid polling interval options
    static let pollingIntervalOptions = [5, 10, 30, 60]
}
