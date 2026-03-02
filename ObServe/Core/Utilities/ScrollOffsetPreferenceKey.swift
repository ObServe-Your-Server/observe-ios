//
//  ScrollOffsetPreferenceKey.swift
//  ObServe
//
//  Shared preference key for scroll offset detection.
//  Replaces 6 duplicate ScrollPreferenceKey definitions across the app.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
