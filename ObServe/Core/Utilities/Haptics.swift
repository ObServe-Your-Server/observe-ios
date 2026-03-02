//
//  Haptics.swift
//  ObServe
//
//  Created by Carlo Derouaux on 20.07.25.
//

import Foundation
import UIKit

enum Haptics {
    static func click() {
        // Check if haptics are enabled in settings
        guard SettingsManager.shared.hapticsEnabled else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        // Check if haptics are enabled in settings
        guard SettingsManager.shared.hapticsEnabled else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
