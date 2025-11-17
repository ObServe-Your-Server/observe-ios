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
    @State private var showAboutModal = false
    @State private var showResetModal = false
    @State private var showPollingIntervalPicker = false
    @State private var showRestartAlert = false
    @Environment(\.dismiss) private var dismiss

    // Use SettingsManager instead of local state
    @ObservedObject private var settings = SettingsManager.shared

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

                    VStack(spacing: 35) {
                        VStack(spacing: 10) {
                            // DATA DISPLAY SECTION
                            sectionHeader("PRECISE DATA")
                            
                            SettingRow(
                                title: "Display metrics with full precision (not rounded)",
                                binding: $settings.preciseDataEnabled
                            )
                        }
                        
                        VStack(spacing: 10) {
                            // INTERACTIONS SECTION
                            sectionHeader("SAFE MODE")
                            
                            SettingRow(
                                title: "Require confirmation for critical actions",
                                binding: $settings.safeModeEnabled
                            )
                        }

                        VStack(spacing: 10) {
                            sectionHeader("HAPTIC")
                            
                            SettingRow(
                                title: "Vibration feedback for button taps",
                                binding: $settings.hapticsEnabled
                            )
                        }
                        
                        VStack(spacing: 10) {
                            sectionHeader("AUTO-CONNECT")
                            SettingRow(
                                title: "Automatically connect to servers when app opens",
                                binding: $settings.autoConnectOnLaunch
                            )
                        }
                        
                        VStack(spacing: 10) {
                            // PERFORMANCE SECTION
                            sectionHeader("POLLING INTERVAL")
                            
                            // Polling Interval Picker
                            Button(action: {
                                showPollingIntervalPicker = true
                            }) {
                                HStack(alignment: .center, spacing: 16) {
                                    Text("How often to fetch new metric data")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    Spacer()
                                    
                                    Text(settings.pollingIntervalLabel())
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        VStack(spacing: 10) {
                            // DATA MANAGEMENT SECTION
                            sectionHeader("RESET DATA")
                            
                            Button(action: {showResetModal = true}) {
                                HStack(alignment: .center, spacing: 16) {
                                    Text("Clear data and reset settings")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        VStack(spacing: 10) {
                            // ABOUT SECTION
                            sectionHeader("ABOUT")
                            
                            Button(action: { showAboutModal = true }) {
                                HStack(spacing: 12) {
                                    Image("AppIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                    
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ABOUT ObServe")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
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
        .fullScreenCover(isPresented: $showAboutModal) {
            AboutObServeView()
        }
        .fullScreenCover(isPresented: $showResetModal) {
            ResetObServeView()
        }
        .confirmationDialog("Polling Interval", isPresented: $showPollingIntervalPicker, titleVisibility: .visible) {
            ForEach(SettingsManager.pollingIntervalOptions, id: \.self) { interval in
                Button(intervalLabel(for: interval)) {
                    print("⚙️ Settings: User selected \(interval) seconds")
                    settings.pollingIntervalSeconds = interval
                    print("⚙️ Settings: Value set to \(settings.pollingIntervalSeconds)")
                    Haptics.click()
                    showRestartAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("How often should ObServe fetch new metric data?")
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now", role: .destructive) {
                exit(0)
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Please restart the app to apply the new polling interval.")
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

    // MARK: - Helper Views
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

    @ViewBuilder
    private func navigationButton(
        icon: String = "",
        title: String,
        description: String,
        action: @escaping () -> Void,
        useImageAsset: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !icon.isEmpty {
                    if useImageAsset {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }

    private func intervalLabel(for seconds: Int) -> String {
        switch seconds {
        case 1: return "1 second"
        case 5: return "5 seconds"
        case 10: return "10 seconds"
        case 30: return "30 seconds"
        case 60: return "1 minute"
        default: return "\(seconds) seconds"
        }
    }
}

/// A single settings row with title, description, and toggle switch
public struct SettingRow: View {
    var title: String
    @Binding var binding: Bool

    public var body: some View {
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
