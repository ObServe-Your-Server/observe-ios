//
//  SettingsOverview.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI

struct SettingsOverview: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                SettingsAppBar(
                    contentHasScrolled: $contentHasScrolled,
                    showBurgerMenu: $showBurgerMenu,
                    versionText: "Version 1.0.0"
                )

                ScrollView {
                    scrollDetection
                    VStack(spacing: 0) {
                        // später die Sections
                        Rectangle().fill(.clear).frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "scroll")
            }
            .background(Color.black.ignoresSafeArea())

            if showBurgerMenu {
                BurgerMenu(
                    onDismiss: { showBurgerMenu = false },
                    onOverView: { dismiss() },
                    onSettings: { showBurgerMenu = false }
                )
            }
        }
    }

    // MARK: - Scroll Detection (steuert die Linie in der AppBar)
    private var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
}

private struct SettingsScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    SettingsOverview()
}
