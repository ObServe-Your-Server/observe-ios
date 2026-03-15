import SwiftUI

/// The type of right-side button displayed in the app bar.
enum AppBarButtonType {
    case hamburgerMenu
    case close
}

struct BaseAppBar<SecondaryContent: View>: View {
    let title: String
    @Binding var contentHasScrolled: Bool
    let rightButtonType: AppBarButtonType
    let rightButtonAction: () -> Void
    @ViewBuilder let secondaryContent: () -> SecondaryContent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)

                secondaryContent()
            }

            Spacer()

            rightButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.black)
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                if contentHasScrolled {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
                }
            }
        )
    }

    @ViewBuilder
    private var rightButton: some View {
        switch rightButtonType {
        case .hamburgerMenu:
            VStack(spacing: 7) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 24, height: 2.5)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 24, height: 2.5)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 24, height: 2.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .frame(width: 40, height: 40)
            .background(Color("ButtonBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .accessibilityIdentifier("burgerMenuButton")
            .onTapGesture { rightButtonAction() }

        case .close:
            Button(action: rightButtonAction) {
                ZStack {
                    Image(systemName: "xmark")
                        .font(.plexSans(size: 30, weight: .light))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
}

/// Extension to support app bars without secondary content
extension BaseAppBar where SecondaryContent == EmptyView {
    init(
        title: String,
        contentHasScrolled: Binding<Bool>,
        rightButtonType: AppBarButtonType,
        rightButtonAction: @escaping () -> Void
    ) {
        self.title = title
        _contentHasScrolled = contentHasScrolled
        self.rightButtonType = rightButtonType
        self.rightButtonAction = rightButtonAction
        secondaryContent = { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 20) {
        BaseAppBar(
            title: "PREVIEW TITLE",
            contentHasScrolled: .constant(false),
            rightButtonType: .hamburgerMenu,
            rightButtonAction: {}
        ) {
            Text("Secondary content here")
                .font(.plexSans(size: 11))
                .foregroundColor(.white)
        }

        BaseAppBar(
            title: "WITH CLOSE BUTTON",
            contentHasScrolled: .constant(true),
            rightButtonType: .close,
            rightButtonAction: {}
        )
    }
    .background(Color.black)
}
