import SwiftUI

extension Font {
    /// IBM Plex Sans variable font, mapped by weight.
    /// Falls back to the system font for `.monospaced` design contexts.
    static func plexSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(IBMPlexSans.postScriptName(for: weight), size: size)
    }

    private enum IBMPlexSans {
        static func postScriptName(for weight: Font.Weight) -> String {
            switch weight {
            case .ultraLight: "IBMPlexSans-ExtraLight"
            case .thin: "IBMPlexSans-Thin"
            case .light: "IBMPlexSans-Light"
            case .regular: "IBMPlexSans-Regular"
            case .medium: "IBMPlexSans-Medium"
            case .semibold: "IBMPlexSans-SemiBold"
            case .bold: "IBMPlexSans-Bold"
            case .heavy: "IBMPlexSans-Bold"
            case .black: "IBMPlexSans-Bold"
            default: "IBMPlexSans-Regular"
            }
        }
    }
}
