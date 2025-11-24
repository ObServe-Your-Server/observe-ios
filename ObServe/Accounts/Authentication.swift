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

    private var bearerToken: String { return "Bearer \(accessToken ?? "")" }

    private var baseURL: String {
        return "https://watch-tower.observe.vision/v1/user/auth"
    }

    init() {
        loadTokensFromKeychain()
    }
    
    func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
    
    private func createAuthRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - Token Management

    private func loadTokensFromKeychain() {
        let tokens = keychainManager.loadTokens()
        self.accessToken = tokens.accessToken
        self.refreshToken = tokens.refreshToken
    }

    private func saveTokensToKeychain(accessToken: String, refreshToken: String, rememberMe: Bool) {
        if rememberMe {
            keychainManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
            keychainManager.saveRememberMe(true)
        }
    }

    private func clearTokensFromKeychain() {
        keychainManager.clearTokens()
        keychainManager.clearRememberMe()
    }

    public func validateAndRefreshIfNeeded(completion: @escaping (Bool) -> Void) {
        // If no tokens exist, user needs to login
        guard accessToken != nil, refreshToken != nil else {
            DispatchQueue.main.async {
                self.isAuthenticated = false
                completion(false)
            }
            return
        }

        // Check if token is still valid
        timeLeft { [weak self] seconds in
            guard let self = self else { return }

            if let seconds = seconds {
                if seconds > 120 {
                    DispatchQueue.main.async {
                        self.isAuthenticated = true
                        self.startRefreshTimer()
                        completion(true)
                    }
                } else {
                    // Token is expiring soon, refresh it
                    print("Token expiring soon (\(seconds)s left), refreshing...")
                    self.refreshWithCompletion { success in
                        completion(success)
                        if success {
                            self.startRefreshTimer()
                        }
                    }
                }
            } else {
                // Token validation failed, try to refresh
                print("Token validation failed, attempting refresh...")
                self.refreshWithCompletion { success in
                    completion(success)
                    if success {
                        self.startRefreshTimer()
                    }
                }
            }
        }
    }

    // MARK: - Token Refresh Timer

    public func startRefreshTimer() {
        stopRefreshTimer()

        // Check token every 5 minutes (300 seconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkAndRefreshToken()
        }
    }

    public func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func checkAndRefreshToken() {
        timeLeft { [weak self] seconds in
            guard let self = self else { return }

            if let seconds = seconds {
                if seconds < 120 {
                    // Less than 2 minutes left, refresh proactively
                    print("Token expiring soon (\(seconds)s left), refreshing proactively...")
                    self.refreshWithCompletion { success in
                        if !success {
                            print("Proactive refresh failed")
                        }
                    }
                }
            } else {
                print("Failed to check token expiry - may be offline")
            }
        }
    }

    // MARK: - Authentication Methods

    public func login(username_or_email: String, password: String, rememberMe: Bool) {
        struct RequestBody : Codable {
            let username_or_email: String
            let password: String
        }

        struct User: Codable {
            let id: Int
            let username: String
            let email: String
            let role: String
            let created_at: String
            let updated_at: String
        }

        struct AuthResponse: Codable {
            let message: String
            let user: User
            let access_token: String
            let refresh_token: String
        }

        guard let url = buildURL(endpoint: "/login") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(username_or_email: username_or_email, password: password)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Failed to encode request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    print("Login successful: \(authResponse.message)")

                    DispatchQueue.main.async {
                        self?.accessToken = authResponse.access_token
                        self?.refreshToken = authResponse.refresh_token
                        self?.saveTokensToKeychain(accessToken: authResponse.access_token,
                                                   refreshToken: authResponse.refresh_token,
                                                   rememberMe: rememberMe)
                        self?.isAuthenticated = true
                        self?.startRefreshTimer()
                    }
                } catch {
                    print("Failed to decode response: \(error)")
                }
            } else {
                // Handle error response
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    print("Login failed: \(message)")
                } else {
                    print("Login failed with status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    public func register(username: String, email: String, password: String, rememberMe: Bool) {
        struct RequestBody : Codable {
            let username: String
            let email: String
            let password: String
        }

        struct User: Codable {
            let id: Int
            let username: String
            let email: String
            let role: String
            let created_at: String
            let updated_at: String
        }

        struct AuthResponse: Codable {
            let message: String
            let user: User
            let access_token: String
            let refresh_token: String
        }

        guard let url = buildURL(endpoint: "/register") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(username: username, email: email, password: password)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Failed to encode request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            if httpResponse.statusCode == 201 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    print("Registration successful: \(authResponse.message)")

                    DispatchQueue.main.async {
                        self?.accessToken = authResponse.access_token
                        self?.refreshToken = authResponse.refresh_token
                        self?.saveTokensToKeychain(accessToken: authResponse.access_token,
                                                   refreshToken: authResponse.refresh_token,
                                                   rememberMe: rememberMe)
                        self?.isAuthenticated = true
                        self?.startRefreshTimer()
                    }
                } catch {
                    print("Failed to decode response: \(error)")
                }
            } else {
                // Handle error response
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    print("Registration failed: \(message)")
                } else {
                    print("Registration failed with status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    public func logout() {
        guard let accessToken = accessToken else {
            print("No access token available")
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            return
        }

        guard let url = buildURL(endpoint: "/logout") else {
            print("Invalid URL")
            return
        }

        var request = createAuthRequest(for: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error during logout: \(error)")
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response during logout")
                return
            }

            if httpResponse.statusCode == 200 {
                print("Logout successful")
            } else {
                print("Logout failed with status code: \(httpResponse.statusCode)")
            }

            // Clear tokens and set isAuthenticated to false regardless of server response
            DispatchQueue.main.async {
                self?.stopRefreshTimer()
                self?.accessToken = nil
                self?.refreshToken = nil
                self?.clearTokensFromKeychain()
                self?.isAuthenticated = false
            }
        }.resume()
    }

    private func refreshWithCompletion(completion: @escaping (Bool) -> Void) {
        struct RequestBody: Codable {
            let refresh_token: String
        }

        struct User: Codable {
            let id: Int
            let username: String
            let email: String
            let role: String
            let created_at: String
            let updated_at: String
        }

        struct AuthResponse: Codable {
            let message: String
            let user: User
            let access_token: String
            let refresh_token: String
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

        guard let url = buildURL(endpoint: "/refresh") else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(refresh_token: refreshToken)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Failed to encode request body: \(error)")
            completion(false)
            return
        }

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

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response during token refresh")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data returned during token refresh")
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    print("Token refresh successful: \(authResponse.message)")

                    let rememberMe = self.keychainManager.loadRememberMe()

                    // Store new tokens (old refresh token is automatically revoked by server)
                    DispatchQueue.main.async {
                        self.accessToken = authResponse.access_token
                        self.refreshToken = authResponse.refresh_token
                        self.saveTokensToKeychain(accessToken: authResponse.access_token,
                                                  refreshToken: authResponse.refresh_token,
                                                  rememberMe: rememberMe)
                        self.isAuthenticated = true
                        completion(true)
                    }
                } catch {
                    print("Failed to decode token refresh response: \(error)")
                    completion(false)
                }
            } else if httpResponse.statusCode == 401 {
                // Refresh token is invalid or expired - log user out
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
                // Handle other error responses
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

    public func refresh() {
        struct RequestBody: Codable {
            let refresh_token: String
        }

        struct User: Codable {
            let id: Int
            let username: String
            let email: String
            let role: String
            let created_at: String
            let updated_at: String
        }

        struct AuthResponse: Codable {
            let message: String
            let user: User
            let access_token: String
            let refresh_token: String
        }

        guard let refreshToken = refreshToken else {
            print("No refresh token available")
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            return
        }

        guard let url = buildURL(endpoint: "/refresh") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(refresh_token: refreshToken)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Failed to encode request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error during token refresh: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response during token refresh")
                return
            }

            guard let data = data else {
                print("No data returned during token refresh")
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    print("Token refresh successful: \(authResponse.message)")

                    // Store new tokens (old refresh token is automatically revoked by server)
                    DispatchQueue.main.async {
                        let rememberMe = self?.keychainManager.loadRememberMe() ?? false
                        self?.accessToken = authResponse.access_token
                        self?.refreshToken = authResponse.refresh_token
                        self?.saveTokensToKeychain(accessToken: authResponse.access_token,
                                                   refreshToken: authResponse.refresh_token,
                                                   rememberMe: rememberMe)
                    }
                } catch {
                    print("Failed to decode token refresh response: \(error)")
                }
            } else if httpResponse.statusCode == 401 {
                // Refresh token is invalid or expired - log user out
                print("Refresh token invalid or expired")
                DispatchQueue.main.async {
                    self?.stopRefreshTimer()
                    self?.accessToken = nil
                    self?.refreshToken = nil
                    self?.clearTokensFromKeychain()
                    self?.isAuthenticated = false
                }
            } else {
                // Handle other error responses
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    print("Token refresh failed: \(message)")
                } else {
                    print("Token refresh failed with status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    public func timeLeft(completion: @escaping (Int?) -> Void) {
        struct TimeLeftResponse: Codable {
            let time_left_seconds: Int
        }

        guard let url = buildURL(endpoint: "/me/accesstimeleft") else {
            print("Invalid URL")
            completion(nil)
            return
        }

        var request = createAuthRequest(for: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error during time left check: \(error)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response during time left check")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data returned during time left check")
                completion(nil)
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let timeLeftResponse = try JSONDecoder().decode(TimeLeftResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(timeLeftResponse.time_left_seconds)
                    }
                } catch {
                    print("Failed to decode time left response: \(error)")
                    completion(nil)
                }
            } else if httpResponse.statusCode == 401 {
                print("Token invalid or expired")
                DispatchQueue.main.async {
                    completion(nil)
                }
            } else {
                print("Time left check failed with status code: \(httpResponse.statusCode)")
                completion(nil)
            }
        }.resume()
    }

    public func getCurrentUser(completion: @escaping (Result<User, UserError>) -> Void) {
        guard let url = buildURL(endpoint: "/me") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = createAuthRequest(for: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error during get current user: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let response = try JSONDecoder().decode(UserResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(response.user))
                    }
                } catch {
                    print("Failed to decode user response: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(.decodingError(error.localizedDescription)))
                    }
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized))
                }
            } else {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError("Request failed with status code: \(httpResponse.statusCode)")))
                    }
                }
            }
        }.resume()
    }

    public func updateCurrentUser(updateRequest: UpdateUserRequest, completion: @escaping (Result<AuthResponse, UserError>) -> Void) {
        guard let url = buildURL(endpoint: "/me") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = createAuthRequest(for: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(updateRequest)
        } catch {
            print("Failed to encode update request: \(error)")
            completion(.failure(.encodingError(error.localizedDescription)))
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Network error during update user: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            if httpResponse.statusCode == 200 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    print("User update successful: \(authResponse.message)")

                    // Update tokens with new ones from response
                    let rememberMe = self.keychainManager.loadRememberMe()

                    DispatchQueue.main.async {
                        self.accessToken = authResponse.access_token
                        self.refreshToken = authResponse.refresh_token
                        self.saveTokensToKeychain(accessToken: authResponse.access_token,
                                                  refreshToken: authResponse.refresh_token,
                                                  rememberMe: rememberMe)
                        completion(.success(authResponse))
                    }
                } catch {
                    print("Failed to decode update response: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(.decodingError(error.localizedDescription)))
                    }
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized))
                }
            } else if httpResponse.statusCode == 400 {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.badRequest(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.badRequest("Invalid request")))
                    }
                }
            } else if httpResponse.statusCode == 409 {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.conflict(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.conflict("Username or email already exists")))
                    }
                }
            } else {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError("Request failed with status code: \(httpResponse.statusCode)")))
                    }
                }
            }
        }.resume()
    }

    public func deleteCurrentUser(password: String, completion: @escaping (Result<String, UserError>) -> Void) {
        guard let url = buildURL(endpoint: "/me") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = createAuthRequest(for: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deleteRequest = DeleteUserRequest(current_password: password)

        do {
            request.httpBody = try JSONEncoder().encode(deleteRequest)
        } catch {
            print("Failed to encode delete request: \(error)")
            completion(.failure(.encodingError(error.localizedDescription)))
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Network error during delete user: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            if httpResponse.statusCode == 200 {
                if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = responseDict["message"] as? String {
                    print("User delete successful: \(message)")

                    // Clear tokens and log out
                    DispatchQueue.main.async {
                        self.stopRefreshTimer()
                        self.accessToken = nil
                        self.refreshToken = nil
                        self.clearTokensFromKeychain()
                        self.isAuthenticated = false
                        completion(.success(message))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.stopRefreshTimer()
                        self.accessToken = nil
                        self.refreshToken = nil
                        self.clearTokensFromKeychain()
                        self.isAuthenticated = false
                        completion(.success("Account successfully deleted"))
                    }
                }
            } else if httpResponse.statusCode == 401 {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.unauthorized))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.unauthorized))
                    }
                }
            } else if httpResponse.statusCode == 400 {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.badRequest(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.badRequest("Invalid request")))
                    }
                }
            } else {
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError("Request failed with status code: \(httpResponse.statusCode)")))
                    }
                }
            }
        }.resume()
    }
}

// MARK: - User Management Models

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let created_at: String
    let updated_at: String
}

struct UserResponse: Codable {
    let user: User
}

struct UpdateUserRequest: Codable {
    let username: String?
    let email: String?
    let password: String?
    let currentPassword: String?

    enum CodingKeys: String, CodingKey {
        case username
        case email
        case password
        case currentPassword = "current_password"
    }
}

struct DeleteUserRequest: Codable {
    let current_password: String
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let access_token: String
    let refresh_token: String
}

enum UserError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case invalidResponse
    case noData
    case decodingError(String)
    case encodingError(String)
    case unauthorized
    case badRequest(String)
    case conflict(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .encodingError(let message):
            return "Failed to encode request: \(message)"
        case .unauthorized:
            return "Unauthorized - please check your credentials"
        case .badRequest(let message):
            return message
        case .conflict(let message):
            return message
        case .serverError(let message):
            return message
        }
    }
}
