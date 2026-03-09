import SwiftUI

enum MenuSection: String, CaseIterable {
    case dashboard = "DASHBOARD"
    // case server = "SERVER"
    // case alerts = "ALERTS"
    case account = "ACCOUNT"
    case settings = "SETTINGS"
    case logout = "LOGOUT"

    var iconOff: String {
        switch self {
        case .dashboard: "dashboardIcon_off"
        // case .server: return "serverIcon_off"
        // case .alerts: return "alertsIcon_off"
        case .account: "accountIcon_off"
        case .settings: "settingsIcon_off"
        case .logout: "logoutIcon_off"
        }
    }

    var iconOn: String {
        switch self {
        case .dashboard: "dashboardIcon_on"
        // case .server: return "serverIcon_on"
        // case .alerts: return "alertsIcon_on"
        case .account: "accountIcon_on"
        case .settings: "settingsIcon_on"
        case .logout: "logoutIcon_on"
        }
    }
}

struct BurgerMenu: View {
    var router: Router
    var selectedSection: MenuSection
    @Binding var isOpen: Bool
    var onDashboard: () -> Void
    var onLogout: () -> Void

    private let menuWidth: CGFloat = 240

    private let openSpring = Animation.spring(response: 0.28, dampingFraction: 0.9)
    private let closeSpring = Animation.spring(response: 0.2, dampingFraction: 0.95)

    var body: some View {
        ZStack(alignment: .trailing) {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Header with app icon and version
                HStack(spacing: 0) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ObServe")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)

                // Menu items
                VStack(spacing: 10) {
                    ForEach(MenuSection.allCases, id: \.self) { section in
                        MenuItemView(
                            section: section,
                            isSelected: selectedSection == section,
                            action: {
                                dismiss {
                                    handleSectionTap(section)
                                }
                            }
                        )
                    }
                }
                Spacer()
            }
            .frame(width: menuWidth)
            .frame(maxHeight: .infinity)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .fill(Color("MenuAccentStroke"))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity),
                alignment: .leading
            )
            .offset(x: isOpen ? 0 : menuWidth)
        }
        .animation(isOpen ? openSpring : closeSpring, value: isOpen)
        .allowsHitTesting(isOpen)
    }

    // MARK: - Helpers

    private func dismiss(after action: (() -> Void)? = nil) {
        isOpen = false
        if let action {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                action()
            }
        }
    }

    private func handleSectionTap(_ section: MenuSection) {
        switch section {
        case .dashboard:
            onDashboard()
        case .logout:
            onLogout()
        default:
            router.navigate(to: section)
        }
    }
}

// MARK: - Menu Item View

struct MenuItemView: View {
    let section: MenuSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(isSelected ? section.iconOn : section.iconOff)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundColor(isSelected ? .white : Color("ObServeGray"))

                Text(section.rawValue)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : Color("ObServeGray"))

                Spacer()
            }
            .padding(.leading, 30)
            .padding(.vertical, 16)
            .background(
                HStack(spacing: 0) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color("MenuAccentStroke"))
                            .frame(width: 3)

                        Color("MenuSelectedBackground")
                    }
                }
                .offset(x: 15)
            )
        }
    }
}
