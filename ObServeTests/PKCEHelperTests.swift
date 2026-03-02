//
//  PKCEHelperTests.swift
//  ObServeTests
//
//  Tests for PKCE utilities and OAuth configuration constants.
//

import Testing
import Foundation
@testable import ObServe

struct PKCEHelperTests {

    // MARK: - Code Verifier

    @Test func generateCodeVerifierIsNotEmpty() {
        let verifier = PKCEHelper.generateCodeVerifier()
        #expect(!verifier.isEmpty)
    }

    @Test func generateCodeVerifierIsBase64URLSafe() {
        let verifier = PKCEHelper.generateCodeVerifier()
        // Should not contain standard base64 characters that are not URL-safe
        #expect(!verifier.contains("+"))
        #expect(!verifier.contains("/"))
        #expect(!verifier.contains("="))
    }

    @Test func generateCodeVerifierIsUnique() {
        let v1 = PKCEHelper.generateCodeVerifier()
        let v2 = PKCEHelper.generateCodeVerifier()
        #expect(v1 != v2)
    }

    @Test func generateCodeVerifierHasReasonableLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        // 32 random bytes → base64 is ~43 chars, trimmed of padding
        #expect(verifier.count >= 40)
        #expect(verifier.count <= 50)
    }

    // MARK: - Code Challenge

    @Test func generateCodeChallengeFromVerifier() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)
        #expect(challenge != nil)
        #expect(!challenge!.isEmpty)
    }

    @Test func generateCodeChallengeIsBase64URLSafe() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)!
        #expect(!challenge.contains("+"))
        #expect(!challenge.contains("/"))
        #expect(!challenge.contains("="))
    }

    @Test func generateCodeChallengeIsDeterministic() {
        let verifier = "test-verifier-string"
        let c1 = PKCEHelper.generateCodeChallenge(from: verifier)
        let c2 = PKCEHelper.generateCodeChallenge(from: verifier)
        #expect(c1 == c2)
    }

    @Test func generateCodeChallengeDiffersForDifferentVerifiers() {
        let c1 = PKCEHelper.generateCodeChallenge(from: "verifier-one")
        let c2 = PKCEHelper.generateCodeChallenge(from: "verifier-two")
        #expect(c1 != c2)
    }

    @Test func generateCodeChallengeHasReasonableLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)!
        // SHA256 hash → 32 bytes → base64 is ~43 chars
        #expect(challenge.count >= 40)
        #expect(challenge.count <= 50)
    }

    // MARK: - State

    @Test func generateStateReturnsUUIDFormat() {
        let state = PKCEHelper.generateState()
        #expect(UUID(uuidString: state) != nil)
    }

    @Test func generateStateIsUnique() {
        let s1 = PKCEHelper.generateState()
        let s2 = PKCEHelper.generateState()
        #expect(s1 != s2)
    }

    // MARK: - OAuth Configuration Constants

    @Test func oauthEndpointsAreWellFormed() {
        #expect(OAuthConfiguration.authorizationEndpoint.contains("/authorize/"))
        #expect(OAuthConfiguration.tokenEndpoint.contains("/token/"))
        #expect(OAuthConfiguration.userInfoEndpoint.contains("/userinfo/"))
    }

    @Test func oauthScopesIncludeRequired() {
        let scopes = OAuthConfiguration.scopes
        #expect(scopes.contains("openid"))
        #expect(scopes.contains("offline_access"))
    }

    @Test func oauthRedirectURIHasCustomScheme() {
        #expect(OAuthConfiguration.redirectURI.hasPrefix("observe://"))
    }

    @Test func oauthClientIDIsNotEmpty() {
        #expect(!OAuthConfiguration.clientID.isEmpty)
    }
}
