//
//  OAuthConfiguration.swift
//  ObServe
//
//  Created by Claude Code on 25.02.26.
//

import Foundation
import CryptoKit

struct OAuthConfiguration {
    // MARK: - Authentik Configuration
    // TODO: Update this URL for production deployment
    static let authentikBaseURL = "https://authentik.marco-brandt.com"
    static let clientID = "NMBN3kraAORJ5VGff2Xy8cHUKaSRU1aYOlGdluep"
    static let redirectURI = "observe://oauth-callback"

    // MARK: - OAuth Endpoints
    static let authorizationEndpoint = "\(authentikBaseURL)/application/o/authorize/"
    static let tokenEndpoint = "\(authentikBaseURL)/application/o/token/"
    static let userInfoEndpoint = "\(authentikBaseURL)/application/o/userinfo/"

    // MARK: - Scopes
    static let scopes = ["openid", "profile", "email", "offline_access"]
}

// MARK: - PKCE Utilities
struct PKCEHelper {
    /// Generates a cryptographically secure random code verifier
    /// Returns a base64url-encoded string of 32 random bytes
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Generates a SHA256 code challenge from the given verifier
    /// Returns a base64url-encoded string of the hash
    static func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Generates a random state parameter for CSRF protection
    static func generateState() -> String {
        return UUID().uuidString
    }
}
