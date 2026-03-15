import SwiftUI

struct LoginViewOAuth: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var oauthManager = OAuthManager()

    var body: some View {
        VStack(spacing: 0) {
            // Branding at the top
            HStack(spacing: 0) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ObServe")
                        .font(.plexSans(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    Text("MONITOR YOUR MACHINES")
                        .font(.plexSans(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .offset(x: -10)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            // Login and Sign Up buttons at the bottom
            VStack(spacing: 12) {
                if oauthManager.isAuthenticating {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    RegularButton(
                        Label: "LOG IN",
                        action: { oauthManager.startOAuthFlow(isSignUp: false) },
                        color: "ObServeBlue"
                    )

                    RegularButton(
                        Label: "SIGN UP",
                        action: { oauthManager.startOAuthFlow(isSignUp: true) },
                        color: "ObServeGray"
                    )

                    if let error = oauthManager.authError {
                        Text(error.localizedDescription)
                            .font(.plexSans(size: 11))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            oauthManager.authenticationManager = authManager
        }
    }
}

#Preview {
    LoginViewOAuth()
        .environmentObject(AuthenticationManager())
}
