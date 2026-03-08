import SwiftUI

struct CornerButton: View {
    var label: String
    var color: Color = .white
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
            Haptics.click()
        }) {
            ZStack {
                Text(label)
                    .foregroundColor(color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        FocusCorners(color: color, size: 8, thickness: 1)
                    )
            }
            .innerShadow(
                color: color,
                blur: 25,
                spread: 12,
                offsetX: 0,
                offsetY: 0,
                opacity: 0.1
            )
        }
    }
}
