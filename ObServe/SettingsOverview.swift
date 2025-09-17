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
    @Environment(\.dismiss) private var dismiss

    // Zustände für die Switches
    @State private var preciseData = false
    @State private var showIcons = true
    @State private var otherSetting = false

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

                    VStack(spacing: 18) {

                        // SECTION 1
                        sectionHeader("PRECISE DATA")
                        SettingRow(
                            title: "When active, data won’t be rounded",
                            binding: $preciseData
                        )
                        
                        Divider()
                            .overlay(Color.white.opacity(0.15))
                            .padding(.vertical, 20)
                            .padding(.trailing, -20)

                        // SECTION 2
                        sectionHeader("SHOW ICONS")
                        SettingRow(
                            title: "Each machine shows an icon based on its type",
                            binding: $showIcons
                        )

                        // SECTION 3
                        sectionHeader("OTHER SETTING")
                        SettingRow(
                            title: "This is a settings description that says what switching the toggle does",
                            binding: $otherSetting
                        )

                        Rectangle().fill(.clear).frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
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
            Color.clear.preference(key: SettingsScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(SettingsScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }

    // MARK: - Kleine Helfer
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
    }
}

/// Eine einzelne Settings‑Zeile mit deiner Custom‑Switch rechts
private struct SettingRow: View {
    var title: String
    @Binding var binding: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()

            Switch(isOn: $binding)
        }
    }
}

private struct SettingsScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview {
    SettingsOverview()
        .background(Color.black)
}
