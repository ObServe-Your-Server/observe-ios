//
//  Authentication.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.11.25.
//

import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false

    private var accessToken: String?
    private var refreshToken: String?
    private var refreshTimer: Timer?
    private let keychainManager = KeychainManager.shared

    var bearerToken: String { return "Bearer \(accessToken ?? "")" }

    init() {
        loadTokensFromKeychain()
    }

    // MARK: - Token Management

    private func loadTokensFromKeychain() {
        let tokens = keychainManager.loadTokens()
        self.accessToken = tokens.accessToken
        self.refreshToken = tokens.refreshToken
    }

    private func saveTokensToKeychain(accessToken: String, refreshToken: String) {
        keychainManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    private func clearTokensFromKeychain() {
        keychainManager.clearTokens()
    }

    public func validateAndRefreshIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken, !refreshToken.isEmpty else {
            print("No refresh token found - user needs to login")
            DispatchQueue.main.async {
                self.isAuthenticated = false
                completion(false)
            }
            return
        }

        // If we have a refresh token, try to refresh the access token.
        // This allows users to stay logged in for 30 days (Authentik refresh token lifetime).
        print("Found refresh token - attempting to refresh access token...")
        refreshWithCompletion { [weak self] success in
            if success {
                print("Token refresh successful - user authenticated")
                self?.startRefreshTimer()
                completion(true)
            } else {
                print("Token refresh failed - user needs to re-login")
                completion(false)
            }
        }
    }

    // MARK: - Token Refresh Timer

    public func startRefreshTimer() {
        stopRefreshTimer()
        // Refresh every 5 minutes to keep the access token alive
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshWithCompletion { success in
                if !success {
                    print("Proactive token refresh failed")
                }
            }
        }
    }

    public func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Logout

    public func logout() {
        print("Logging out - clearing local tokens")
        if let refreshToken = refreshToken {
            revokeAuthentikToken(token: refreshToken)
        }
        DispatchQueue.main.async {
            self.stopRefreshTimer()
            self.accessToken = nil
            self.refreshToken = nil
            self.clearTokensFromKeychain()
            self.isAuthenticated = false
            print("Logout successful")
        }
    }

    private func revokeAuthentikToken(token: String) {
        guard let url = URL(string: OAuthConfiguration.tokenEndpoint.replacingOccurrences(of: "/token/", with: "/revoke/")) else {
            print("Invalid revoke URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "token": token,
            "client_id": OAuthConfiguration.clientID,
            "token_type_hint": "refresh_token"
        ]

        let bodyString = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Token revocation failed (non-critical): \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Token revocation status: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    // MARK: - OAuth Token Refresh

    private func refreshWithCompletion(completion: @escaping (Bool) -> Void) {
        struct OAuthTokenResponse: Codable {
            let access_token: String
            let token_type: String
            let expires_in: Int
            let refresh_token: String?
        }

        guard let refreshToken = refreshToken else {
            print("No refresh token available")
            DispatchQueue.main.async {
                self.clearTokensFromKeychain()
                self.isAuthenticated = false
                completion(false)
            }
            return
        }

        guard let url = URL(string: OAuthConfiguration.tokenEndpoint) else {
            print("Invalid token endpoint URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": OAuthConfiguration.clientID
        ]

        let bodyString = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                print("Network error during token refresh: \(error)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                print("Invalid response during token refresh")
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
                    print("Token refresh successful")
                    DispatchQueue.main.async {
                        self.accessToken = tokenResponse.access_token
                        self.refreshToken = tokenResponse.refresh_token ?? self.refreshToken
                        self.saveTokensToKeychain(
                            accessToken: tokenResponse.access_token,
                            refreshToken: tokenResponse.refresh_token ?? self.refreshToken ?? ""
                        )
                        self.isAuthenticated = true
                        completion(true)
                    }
                } catch {
                    print("Failed to decode token refresh response: \(error)")
                    completion(false)
                }
            } else if httpResponse.statusCode == 401 {
                print("Refresh token invalid or expired")
                DispatchQueue.main.async {
                    self.stopRefreshTimer()
                    self.accessToken = nil
                    self.refreshToken = nil
                    self.clearTokensFromKeychain()
                    self.isAuthenticated = false
                    completion(false)
                }
            } else {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    print("Token refresh failed: \(message)")
                } else {
                    print("Token refresh failed with status code: \(httpResponse.statusCode)")
                }
                completion(false)
            }
        }.resume()
    }

    // MARK: - OAuth Authentication

    public func storeOAuthTokens(accessToken: String, refreshToken: String) {
        print("Storing Authentik OAuth tokens")
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveTokensToKeychain(accessToken: accessToken, refreshToken: refreshToken)
        self.isAuthenticated = true
        startRefreshTimer()
    }
}
