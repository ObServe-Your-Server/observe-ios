import SwiftUI

struct AddMachineButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text("ADD MACHINE")
                    .foregroundColor(Color.gray.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }
            .innerShadow(
                color: Color.gray.opacity(0.7),
                blur: 25,
                spread: 12,
                offsetX: 0,
                offsetY: 0,
                opacity: 0.1
            )
        }
        .frame(maxWidth: 160)
        .padding(.horizontal, 5)
        .padding(.bottom, 32)
    }
}
