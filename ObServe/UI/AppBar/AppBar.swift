//
//  AppBar.swift
//  ObServe
//
//  Unified app bar replacing 6 specialized wrappers around BaseAppBar.
//  Provides convenience initializers for each usage pattern:
//    - Dashboard (sort cycle button, hamburger menu)
//    - Detail (interval cycle button, close button)
//    - Onboarding (progress indicator, close button)
//    - Icon+Label secondary button (About, Account, Settings, Reset)
//    - Plain (no secondary content)
//

import SwiftUI

// MARK: - Secondary Content Configuration

/// Describes what secondary content the AppBar should display.
enum AppBarSecondary {
    case none
    case sortCycle(Binding<AppBar.SortType>)
    case intervalCycle(Binding<AppBar.Interval>)
    case progress(currentStep: Int, totalSteps: Int)
    case iconLabel(icon: String, label: String, action: () -> Void)
}

// MARK: - AppBar

struct AppBar: View {

    // MARK: Shared Enums

    enum SortType: String, CaseIterable {
        case all = "ALL"
        case online = "ON"
        case offline = "OFF"
    }

    enum Interval: CaseIterable {
        case s1, s2, s5, s10
        var label: String {
            switch self {
            case .s1:  return "1S"
            case .s2:  return "2S"
            case .s5:  return "5S"
            case .s10: return "10S"
            }
        }
        var seconds: Double {
            switch self {
            case .s1:  return 1
            case .s2:  return 2
            case .s5:  return 5
            case .s10: return 10
            }
        }
    }

    // MARK: Stored Properties

    let title: String
    @Binding var contentHasScrolled: Bool
    let rightButtonType: AppBarButtonType
    let rightButtonAction: () -> Void
    let secondary: AppBarSecondary

    // MARK: Body

    var body: some View {
        BaseAppBar(
            title: title,
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: rightButtonType,
            rightButtonAction: rightButtonAction
        ) {
            secondaryContent
        }
    }

    @ViewBuilder
    private var secondaryContent: some View {
        switch secondary {
        case .none:
            EmptyView()

        case .sortCycle(let binding):
            Button {
                let allCases = SortType.allCases
                if let idx = allCases.firstIndex(of: binding.wrappedValue) {
                    binding.wrappedValue = allCases[(idx + 1) % allCases.count]
                }
            } label: {
                Text("SORT: \(binding.wrappedValue.rawValue)")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color("ButtonBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }

        case .intervalCycle(let binding):
            Button {
                let all = Interval.allCases
                if let i = all.firstIndex(of: binding.wrappedValue) {
                    binding.wrappedValue = all[(i + 1) % all.count]
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Text("INTERVALL: \(binding.wrappedValue.label)")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }

        case .progress(let currentStep, let totalSteps):
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.white : Color.gray.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)

        case .iconLabel(let icon, let label, let action):
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Convenience Initializers

extension AppBar {

    /// Dashboard: shows machine count, sort cycle button, hamburger menu
    init(
        machineCount: Int,
        contentHasScrolled: Binding<Bool>,
        showBurgerMenu: Binding<Bool>,
        selectedSortType: Binding<SortType>
    ) {
        self.title = "\(machineCount) \(machineCount == 1 ? "MACHINE" : "MACHINES")"
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .hamburgerMenu
        self.rightButtonAction = { showBurgerMenu.wrappedValue = true }
        self.secondary = .sortCycle(selectedSortType)
    }

    /// Detail: shows server name, interval cycle button, close button
    init(
        serverName: String,
        contentHasScrolled: Binding<Bool>,
        selectedInterval: Binding<Interval>,
        onClose: @escaping () -> Void
    ) {
        self.title = serverName.uppercased()
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .close
        self.rightButtonAction = onClose
        self.secondary = .intervalCycle(selectedInterval)
    }

    /// Detail with progress indicator (onboarding): shows title, progress steps, close button
    init(
        serverName: String,
        contentHasScrolled: Binding<Bool>,
        currentStep: Int,
        totalSteps: Int,
        onClose: @escaping () -> Void
    ) {
        self.title = serverName.uppercased()
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .close
        self.rightButtonAction = onClose
        self.secondary = .progress(currentStep: currentStep, totalSteps: totalSteps)
    }

    /// Detail with no secondary content (manage server): shows title, close button
    init(
        serverName: String,
        contentHasScrolled: Binding<Bool>,
        onClose: @escaping () -> Void
    ) {
        self.title = serverName.uppercased()
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .close
        self.rightButtonAction = onClose
        self.secondary = .none
    }

    /// Icon+Label with close button (About, Reset)
    init(
        title: String,
        contentHasScrolled: Binding<Bool>,
        onClose: @escaping () -> Void,
        secondaryIcon: String,
        secondaryLabel: String,
        secondaryAction: @escaping () -> Void
    ) {
        self.title = title
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .close
        self.rightButtonAction = onClose
        self.secondary = .iconLabel(icon: secondaryIcon, label: secondaryLabel, action: secondaryAction)
    }

    /// Icon+Label with hamburger menu (Account, Settings)
    init(
        title: String,
        contentHasScrolled: Binding<Bool>,
        showBurgerMenu: Binding<Bool>,
        secondaryIcon: String,
        secondaryLabel: String,
        secondaryAction: @escaping () -> Void = {}
    ) {
        self.title = title
        self._contentHasScrolled = contentHasScrolled
        self.rightButtonType = .hamburgerMenu
        self.rightButtonAction = { showBurgerMenu.wrappedValue = true }
        self.secondary = .iconLabel(icon: secondaryIcon, label: secondaryLabel, action: secondaryAction)
    }
}

// MARK: - Previews

#Preview("Dashboard") {
    AppBar(
        machineCount: 3,
        contentHasScrolled: .constant(false),
        showBurgerMenu: .constant(false),
        selectedSortType: .constant(.all)
    )
    .background(Color.black)
}

#Preview("Detail") {
    AppBar(
        serverName: "ASUS PN-42",
        contentHasScrolled: .constant(false),
        selectedInterval: .constant(.s1),
        onClose: {}
    )
    .background(Color.black)
}

#Preview("Onboarding Progress") {
    AppBar(
        serverName: "ADD MACHINE",
        contentHasScrolled: .constant(false),
        currentStep: 2,
        totalSteps: 4,
        onClose: {}
    )
    .background(Color.black)
}

#Preview("About") {
    AppBar(
        title: "ABOUT ObServe",
        contentHasScrolled: .constant(false),
        onClose: {},
        secondaryIcon: "arrow.up.right",
        secondaryLabel: "WEBSITE",
        secondaryAction: {}
    )
    .background(Color.black)
}

#Preview("Settings") {
    AppBar(
        title: "SETTINGS",
        contentHasScrolled: .constant(false),
        showBurgerMenu: .constant(false),
        secondaryIcon: "arrow.up.right",
        secondaryLabel: "Version 1.0.0"
    )
    .background(Color.black)
}
