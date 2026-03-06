//
//  ErrorEnumTests.swift
//  ObServeTests
//
//  Tests for APIError and OAuthError errorDescription outputs.
//

import Testing
@testable import ObServe

struct APIErrorTests {

    @Test func invalidURLDescription() {
        #expect(APIError.invalidURL.errorDescription == "Invalid URL")
    }

    @Test func notAuthenticatedDescription() {
        #expect(APIError.notAuthenticated.errorDescription == "Not authenticated")
    }

    @Test func unauthorizedDescription() {
        #expect(APIError.unauthorized.errorDescription == "Unauthorized - please log in again")
    }

    @Test func notFoundDescription() {
        #expect(APIError.notFound.errorDescription == "Resource not found")
    }

    @Test func noDataDescription() {
        #expect(APIError.noData.errorDescription == "No data received")
    }

    @Test func serverErrorDescription() {
        #expect(APIError.serverError(500).errorDescription == "Server error (500)")
        #expect(APIError.serverError(503).errorDescription == "Server error (503)")
    }

    @Test func allCasesHaveDescriptions() {
        let cases: [APIError] = [
            .invalidURL, .notAuthenticated, .unauthorized,
            .notFound, .noData, .serverError(500)
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

struct OAuthErrorTests {

    @Test func pkceGenerationFailedDescription() {
        #expect(OAuthError.pkceGenerationFailed.errorDescription == "Failed to generate security parameters")
    }

    @Test func invalidAuthURLDescription() {
        #expect(OAuthError.invalidAuthURL.errorDescription == "Invalid authentication URL")
    }

    @Test func sessionStartFailedDescription() {
        #expect(OAuthError.sessionStartFailed.errorDescription == "Failed to start authentication session")
    }

    @Test func userCancelledDescription() {
        #expect(OAuthError.userCancelled.errorDescription == "Authentication cancelled")
    }

    @Test func authSessionFailedDescription() {
        let error = OAuthError.authSessionFailed("timeout")
        #expect(error.errorDescription == "Authentication failed: timeout")
    }

    @Test func noCallbackURLDescription() {
        #expect(OAuthError.noCallbackURL.errorDescription == "No callback URL received")
    }

    @Test func invalidCallbackURLDescription() {
        #expect(OAuthError.invalidCallbackURL.errorDescription == "Invalid callback URL")
    }

    @Test func authServerErrorDescription() {
        let error = OAuthError.authServerError("access_denied")
        #expect(error.errorDescription == "Authentication server error: access_denied")
    }

    @Test func stateMismatchDescription() {
        #expect(OAuthError.stateMismatch.errorDescription == "Security validation failed")
    }

    @Test func noAuthorizationCodeDescription() {
        #expect(OAuthError.noAuthorizationCode.errorDescription == "No authorization code received")
    }

    @Test func missingCodeVerifierDescription() {
        #expect(OAuthError.missingCodeVerifier.errorDescription == "Missing security verifier")
    }

    @Test func invalidTokenURLDescription() {
        #expect(OAuthError.invalidTokenURL.errorDescription == "Invalid token URL")
    }

    @Test func tokenExchangeFailedDescription() {
        let error = OAuthError.tokenExchangeFailed("network error")
        #expect(error.errorDescription == "Token exchange failed: network error")
    }

    @Test func invalidTokenResponseDescription() {
        #expect(OAuthError.invalidTokenResponse.errorDescription == "Invalid token response")
    }

    @Test func noTokenDataDescription() {
        #expect(OAuthError.noTokenData.errorDescription == "No token data received")
    }

    @Test func tokenDecodingFailedDescription() {
        let error = OAuthError.tokenDecodingFailed("missing field")
        #expect(error.errorDescription == "Failed to decode token: missing field")
    }

    @Test func allCasesHaveNonEmptyDescriptions() {
        let cases: [OAuthError] = [
            .pkceGenerationFailed, .invalidAuthURL, .sessionStartFailed,
            .userCancelled, .authSessionFailed("x"), .noCallbackURL,
            .invalidCallbackURL, .authServerError("x"), .stateMismatch,
            .noAuthorizationCode, .missingCodeVerifier, .invalidTokenURL,
            .tokenExchangeFailed("x"), .invalidTokenResponse,
            .noTokenData, .tokenDecodingFailed("x")
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
