//
//  OAuthManager.swift
//  ObServe
//
//  Created by Claude Code on 25.02.26.
//

import Foundation
import AuthenticationServices
import SwiftUI

class OAuthManager: NSObject, ObservableObject {
    @Published var isAuthenticating = false
    @Published var authError: OAuthError?

    private var authSession: ASWebAuthenticationSession?
    private var codeVerifier: String?
    private var state: String?

    weak var authenticationManager: AuthenticationManager?

    // MARK: - OAuth Flow Initiation
    func startOAuthFlow(isSignUp: Bool = false) {
        isAuthenticating = true
        authError = nil

        // Generate PKCE parameters
        codeVerifier = PKCEHelper.generateCodeVerifier()
        state = PKCEHelper.generateState()

        guard let codeVerifier = codeVerifier,
              let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier),
              let state = state else {
            handleError(.pkceGenerationFailed)
            return
        }

        // Build authorization URL
        guard let authURL = buildAuthorizationURL(
            codeChallenge: codeChallenge,
            state: state,
            isSignUp: isSignUp
        ) else {
            handleError(.invalidAuthURL)
            return
        }

        print("Starting OAuth flow with URL: \(authURL)")

        // Create and start ASWebAuthenticationSession
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "observe"
        ) { [weak self] callbackURL, error in
            self?.handleAuthCallback(callbackURL: callbackURL, error: error)
        }

        // Use ephemeral session (doesn't share cookies with Safari)
        // Set to false if you want SSO with Safari
        authSession?.prefersEphemeralWebBrowserSession = false

        // Provide presentation context
        authSession?.presentationContextProvider = self

        if !authSession!.start() {
            handleError(.sessionStartFailed)
        }
    }

    // MARK: - Authorization URL Builder
    private func buildAuthorizationURL(codeChallenge: String, state: String, isSignUp: Bool = false) -> URL? {
        // Use enrollment endpoint for sign-up flow
        let endpoint = isSignUp ? "\(OAuthConfiguration.authentikBaseURL)/if/flow/observe-enrollment/" : OAuthConfiguration.authorizationEndpoint

        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfiguration.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfiguration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: OAuthConfiguration.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        return components?.url
    }

    // MARK: - Callback Handler
    private func handleAuthCallback(callbackURL: URL?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let error = error {
                // User cancelled or error occurred
                if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    self.handleError(.userCancelled)
                } else {
                    self.handleError(.authSessionFailed(error.localizedDescription))
                }
                return
            }

            guard let callbackURL = callbackURL else {
                self.handleError(.noCallbackURL)
                return
            }

            print("Received callback URL: \(callbackURL)")

            // Parse callback URL
            self.processCallback(url: callbackURL)
        }
    }

    // MARK: - Process OAuth Callback
    private func processCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            handleError(.invalidCallbackURL)
            return
        }

        // Extract parameters
        let code = queryItems.first(where: { $0.name == "code" })?.value
        let returnedState = queryItems.first(where: { $0.name == "state" })?.value
        let error = queryItems.first(where: { $0.name == "error" })?.value

        // Check for errors
        if let error = error {
            handleError(.authServerError(error))
            return
        }

        // Validate state to prevent CSRF
        guard returnedState == state else {
            handleError(.stateMismatch)
            return
        }

        // Validate authorization code
        guard let authorizationCode = code else {
            handleError(.noAuthorizationCode)
            return
        }

        print("Authorization code received: \(authorizationCode.prefix(10))...")

        // Exchange authorization code for tokens
        exchangeCodeForTokens(code: authorizationCode)
    }

    // MARK: - Token Exchange with Authentik
    private func exchangeCodeForTokens(code: String) {
        guard let codeVerifier = codeVerifier else {
            handleError(.missingCodeVerifier)
            return
        }

        guard let url = URL(string: OAuthConfiguration.tokenEndpoint) else {
            handleError(.invalidTokenURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build form parameters
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": OAuthConfiguration.redirectURI,
            "client_id": OAuthConfiguration.clientID,
            "code_verifier": codeVerifier
        ]

        let bodyString = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        print("Exchanging code for tokens...")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.handleError(.tokenExchangeFailed(error.localizedDescription))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.handleError(.invalidTokenResponse)
                return
            }

            guard let data = data else {
                self.handleError(.noTokenData)
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
                    print("OAuth tokens received successfully")

                    guard let refreshToken = tokenResponse.refresh_token, !refreshToken.isEmpty else {
                        self.handleError(.tokenExchangeFailed("No refresh token returned - ensure offline_access scope is enabled in Authentik"))
                        return
                    }

                    // Store Authentik tokens directly in AuthenticationManager
                    DispatchQueue.main.async { [weak self] in
                        self?.authenticationManager?.storeOAuthTokens(
                            accessToken: tokenResponse.access_token,
                            refreshToken: refreshToken
                        )
                        self?.isAuthenticating = false
                        print("OAuth login completed successfully")
                    }
                } catch {
                    self.handleError(.tokenDecodingFailed(error.localizedDescription))
                }
            } else {
                // Try to parse error
                if let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                    self.handleError(.authServerError(errorResponse.error_description ?? errorResponse.error))
                } else {
                    self.handleError(.tokenExchangeFailed("Status code: \(httpResponse.statusCode)"))
                }
            }
        }.resume()
    }

    // MARK: - Error Handling
    private func handleError(_ error: OAuthError) {
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticating = false
            self?.authError = error
            print("OAuth error: \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup
    func reset() {
        authSession?.cancel()
        authSession = nil
        codeVerifier = nil
        state = nil
        isAuthenticating = false
        authError = nil
    }

    // MARK: - Authentik Self-Service Flows

    /// Opens an Authentik self-service flow (e.g. user settings, password change)
    /// in a web browser session. These flows don't return a callback; the user
    /// simply completes the flow and dismisses the browser.
    func openAuthentikFlow(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "observe"
        ) { _, _ in
            // No callback handling needed for self-service flows.
            // The user dismisses the browser when done.
        }

        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()

        // Keep a reference so the session isn't deallocated
        authSession = session
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension OAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window for presentation
        return ASPresentationAnchor()
    }
}

// MARK: - OAuth Models
struct OAuthTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String?
    let id_token: String?
}

struct OAuthErrorResponse: Codable {
    let error: String
    let error_description: String?
}

enum OAuthError: LocalizedError {
    case pkceGenerationFailed
    case invalidAuthURL
    case sessionStartFailed
    case userCancelled
    case authSessionFailed(String)
    case noCallbackURL
    case invalidCallbackURL
    case authServerError(String)
    case stateMismatch
    case noAuthorizationCode
    case missingCodeVerifier
    case invalidTokenURL
    case tokenExchangeFailed(String)
    case invalidTokenResponse
    case noTokenData
    case tokenDecodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .pkceGenerationFailed:
            return "Failed to generate security parameters"
        case .invalidAuthURL:
            return "Invalid authentication URL"
        case .sessionStartFailed:
            return "Failed to start authentication session"
        case .userCancelled:
            return "Authentication cancelled"
        case .authSessionFailed(let message):
            return "Authentication failed: \(message)"
        case .noCallbackURL:
            return "No callback URL received"
        case .invalidCallbackURL:
            return "Invalid callback URL"
        case .authServerError(let message):
            return "Authentication server error: \(message)"
        case .stateMismatch:
            return "Security validation failed"
        case .noAuthorizationCode:
            return "No authorization code received"
        case .missingCodeVerifier:
            return "Missing security verifier"
        case .invalidTokenURL:
            return "Invalid token URL"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .invalidTokenResponse:
            return "Invalid token response"
        case .noTokenData:
            return "No token data received"
        case .tokenDecodingFailed(let message):
            return "Failed to decode token: \(message)"
        }
    }
}
