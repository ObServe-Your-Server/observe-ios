import SwiftUI

struct CoolButton: View {
    var action: () async throws -> Void
    var text: String
    var color: String
    var requiresConfirmation: Bool = false
    var confirmationTitle: String = "Confirm Action"
    var confirmationMessage: String = "Are you sure?"

    @State private var isPerformingTask = false
    @State private var isCompleted = false
    @State private var showConfirmation = false

    var body: some View {
        Button(action: {
            if requiresConfirmation {
                showConfirmation = true
            } else {
                performAction()
            }
        }) {
            ZStack {
                Text(text)
                    .foregroundColor(Color(color))
                    .font(.system(size: 12))
                    .opacity((!isPerformingTask && !isCompleted) ? 1 : 0)
                DotProgressView()
                    .opacity((isPerformingTask && !isCompleted) ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 7)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(color).opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isPerformingTask || isCompleted)
        .confirmationDialog(confirmationTitle, isPresented: $showConfirmation, titleVisibility: .visible) {
            Button(text, role: .destructive) {
                performAction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    private func performAction() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            isPerformingTask = true
        }
        Task {
            try? await action()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                isPerformingTask = false
                isCompleted = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    isCompleted = false
                }
            }
        }
    }
}

struct CoolButton_Previews: PreviewProvider {
    static var previews: some View {
        CoolButton(
            action: {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            },
            text: "TAP ME",
            color: "pink"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
