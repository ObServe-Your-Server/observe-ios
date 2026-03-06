//
//  ScrollOffsetPreferenceKey.swift
//  ObServe
//
//  Shared preference key and ViewModifier for scroll offset detection.
//  Replaces 6 duplicate scrollDetection computed properties across the app.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Scroll Detection View

/// A zero-height view that detects scroll offset within a named "scroll" coordinate space
/// and updates the provided binding when the user has scrolled past the threshold.
///
/// Usage: Place `ScrollDetector(contentHasScrolled: $contentHasScrolled)` at the top
/// of a ScrollView that uses `.coordinateSpace(name: "scroll")`.
struct ScrollDetector: View {
    @Binding var contentHasScrolled: Bool

    var body: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
}
