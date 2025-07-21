import SwiftUI

struct CoolButton: View {
    var action: () async throws -> Void
    var text: String
    var color: String

    @State private var isPerformingTask = false
    @State private var isCompleted = false

    var body: some View {
        Button(action: {
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
        }) {
            ZStack {
                if !isPerformingTask && !isCompleted {
                    Text(text)
                        .foregroundColor(Color(color))
                        .font(.system(size: 12))
                }
                if isPerformingTask && !isCompleted {
                    DotProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 7)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(color).opacity(0.3), lineWidth: 1)
            )
        }
        .opacity(isPerformingTask ? 0.5 : 1)
        .disabled(isPerformingTask || isCompleted)
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
