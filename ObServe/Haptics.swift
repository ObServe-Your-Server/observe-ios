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
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
