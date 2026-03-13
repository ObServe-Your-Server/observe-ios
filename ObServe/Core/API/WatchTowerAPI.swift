import Foundation

class WatchTowerAPI {
    static let shared = WatchTowerAPI()

    private let baseURLs = [
        "https://watch-tower.observe.vision",
        "https://watch-tower-backup.observe.vision",
        "https://watch-tower.marco-brandt.com",
    ]
    private var baseURL: String {
        baseURLs[0]
    }

    private weak var authManager: AuthenticationManager?

    private init() {}

    func configure(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    // MARK: - Generic Request Helpers

    private func createRequest(
        for url: URL,
        method: String = "GET",
        timeoutInterval: TimeInterval? = nil
    )
        -> URLRequest?
    {
        guard let authManager else {
            print("WatchTowerAPI: AuthenticationManager not configured")
            return nil
        }

        var request = URLRequest(url: url)
        if let timeout = timeoutInterval { request.timeoutInterval = timeout }
        request.httpMethod = method
        request.setValue(authManager.bearerToken, forHTTPHeaderField: "Authorization")
        if method != "DELETE", method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    /// Attempts a token refresh when a 401/403 is received.
    /// On success, calls `retryBlock` to re-run the original request.
    /// On failure, logs the user out and completes with `.unauthorized`.
    private func handleUnauthorized<T>(
        retryBlock: @escaping () -> Void,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let authManager else {
            completion(.failure(APIError.unauthorized))
            return
        }
        authManager.refreshWithCompletion { success in
            if success {
                retryBlock()
            } else {
                DispatchQueue.main.async { authManager.logout() }
                completion(.failure(APIError.unauthorized))
            }
        }
    }

    private func buildURL(path: String, queryItems: [URLQueryItem] = [], base: String? = nil) -> URL? {
        var components = URLComponents(string: (base ?? baseURL) + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    /// Returns true if the error is a network-level failure (not an HTTP error), warranting a fallback.
    private func isNetworkFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }

    /// Executes `block` with each base URL in order, retrying on network failures.
    private func performWithFallback<T>(
        urlIndex: Int = 0,
        block: @escaping (String, @escaping (Result<T, Error>) -> Void) -> Void,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard urlIndex < baseURLs.count else {
            completion(.failure(APIError.invalidURL))
            return
        }
        block(baseURLs[urlIndex]) { result in
            switch result {
            case .success:
                completion(result)
            case let .failure(error) where self.isNetworkFailure(error) && urlIndex + 1 < self.baseURLs.count:
                print(
                    "WatchTowerAPI: \(self.baseURLs[urlIndex]) unreachable, trying fallback \(self.baseURLs[urlIndex + 1])"
                )
                self.performWithFallback(urlIndex: urlIndex + 1, block: block, completion: completion)
            case .failure:
                completion(result)
            }
        }
    }

    // MARK: - GET

    func fetch<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        timeoutInterval: TimeInterval? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        performWithFallback(block: { [weak self] base, done in
            guard let self else { return }
            guard let url = buildURL(path: path, queryItems: queryItems, base: base) else {
                done(.failure(APIError.invalidURL))
                return
            }
            guard let request = createRequest(for: url, timeoutInterval: timeoutInterval) else {
                done(.failure(APIError.notAuthenticated))
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    done(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        self.handleUnauthorized(
                            retryBlock: { self.fetch(
                                path: path,
                                queryItems: queryItems,
                                timeoutInterval: timeoutInterval,
                                completion: completion
                            ) },
                            completion: completion
                        )
                        return
                    }
                    if httpResponse.statusCode == 404 {
                        done(.failure(APIError.notFound))
                        return
                    }
                    if httpResponse.statusCode >= 400 {
                        done(.failure(APIError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                guard let data else {
                    done(.failure(APIError.noData))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    done(.success(decoded))
                } catch {
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("WatchTowerAPI: Decoding failed for \(T.self). Raw: \(rawString.prefix(300))")
                    }
                    done(.failure(error))
                }
            }.resume()
        }, completion: completion)
    }

    // MARK: - POST

    func post<Response: Decodable>(
        path: String,
        body: some Encodable,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        guard let encodedBody = try? JSONEncoder().encode(body) else {
            completion(.failure(APIError.noData))
            return
        }
        postDecoded(path: path, encodedBody: encodedBody, completion: completion)
    }

    private func postDecoded<Response: Decodable>(
        path: String,
        encodedBody: Data,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        performWithFallback(block: { [weak self] base, done in
            guard let self else { return }
            guard let url = buildURL(path: path, base: base) else {
                done(.failure(APIError.invalidURL))
                return
            }
            guard var request = createRequest(for: url, method: "POST") else {
                done(.failure(APIError.notAuthenticated))
                return
            }
            request.httpBody = encodedBody
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    done(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        self.handleUnauthorized(
                            retryBlock: {
                                self.postDecoded(path: path, encodedBody: encodedBody, completion: completion)
                            },
                            completion: completion
                        )
                        return
                    }
                    if httpResponse.statusCode >= 400 {
                        done(.failure(APIError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                guard let data else {
                    done(.failure(APIError.noData))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(Response.self, from: data)
                    done(.success(decoded))
                } catch {
                    done(.failure(error))
                }
            }.resume()
        }, completion: completion)
    }

    /// POST that returns raw Data (for endpoints with empty/untyped response bodies)
    func post(path: String, body: some Encodable, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let encodedBody = try? JSONEncoder().encode(body) else {
            completion(.failure(APIError.noData))
            return
        }
        postData(path: path, encodedBody: encodedBody, completion: completion)
    }

    private func postData(path: String, encodedBody: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        performWithFallback(block: { [weak self] base, done in
            guard let self else { return }
            guard let url = buildURL(path: path, base: base) else {
                done(.failure(APIError.invalidURL))
                return
            }
            guard var request = createRequest(for: url, method: "POST") else {
                done(.failure(APIError.notAuthenticated))
                return
            }
            request.httpBody = encodedBody
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    done(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        self.handleUnauthorized(
                            retryBlock: { self.postData(path: path, encodedBody: encodedBody, completion: completion) },
                            completion: completion
                        )
                        return
                    }
                    if httpResponse.statusCode >= 400 {
                        done(.failure(APIError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                done(.success(data ?? Data()))
            }.resume()
        }, completion: completion)
    }

    // MARK: - PUT

    func put(path: String, body: some Encodable, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let encodedBody = try? JSONEncoder().encode(body) else {
            completion(.failure(APIError.noData))
            return
        }
        putData(path: path, encodedBody: encodedBody, completion: completion)
    }

    private func putData(path: String, encodedBody: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        performWithFallback(block: { [weak self] base, done in
            guard let self else { return }
            guard let url = buildURL(path: path, base: base) else {
                done(.failure(APIError.invalidURL))
                return
            }
            guard var request = createRequest(for: url, method: "PUT") else {
                done(.failure(APIError.notAuthenticated))
                return
            }
            request.httpBody = encodedBody
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    done(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        self.handleUnauthorized(
                            retryBlock: { self.putData(path: path, encodedBody: encodedBody, completion: completion) },
                            completion: completion
                        )
                        return
                    }
                    if httpResponse.statusCode >= 400 {
                        done(.failure(APIError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                done(.success(data ?? Data()))
            }.resume()
        }, completion: completion)
    }

    // MARK: - DELETE

    func delete(path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        performWithFallback(block: { [weak self] base, done in
            guard let self else { return }
            guard let url = buildURL(path: path, base: base) else {
                done(.failure(APIError.invalidURL))
                return
            }
            guard let request = createRequest(for: url, method: "DELETE") else {
                done(.failure(APIError.notAuthenticated))
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    done(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        self.handleUnauthorized(
                            retryBlock: { self.delete(path: path, completion: completion) },
                            completion: completion
                        )
                        return
                    }
                    if httpResponse.statusCode >= 400 {
                        if let data, let body = String(data: data, encoding: .utf8) {
                            print("WatchTowerAPI DELETE \(path) failed [\(httpResponse.statusCode)]: \(body)")
                        }
                        done(.failure(APIError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                done(.success(()))
            }.resume()
        }, completion: completion)
    }

    // MARK: - Convenience Methods

    /// Fetch all machines for the authenticated user
    func fetchMachines(completion: @escaping (Result<[MachineEntityResponse], Error>) -> Void) {
        fetch(path: "/v1/machines", completion: completion)
    }

    /// Create a new machine
    func createMachine(
        request: CreateMachineRequest,
        completion: @escaping (Result<MachineEntityResponse, Error>) -> Void
    ) {
        post(path: "/v1/machines", body: request, completion: completion)
    }

    /// Delete a machine
    func deleteMachine(uuid: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        delete(path: "/v1/machines/\(uuid.uuidString)", completion: completion)
    }

    /// Update a machine
    func updateMachine(uuid: UUID, request: UpdateMachineRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        put(path: "/v1/machines/\(uuid.uuidString)", body: request, completion: completion)
    }

    /// Refresh a machine's API key
    func refreshAPIKey(uuid: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        struct EmptyBody: Encodable {}
        post(path: "/v1/machines/\(uuid.uuidString)/api-key/refresh", body: EmptyBody(), completion: completion)
    }

    /// Fetch the authenticated user's profile info
    func fetchUserInfo(completion: @escaping (Result<UserInfoResponse, Error>) -> Void) {
        fetch(path: "/v1/users/me", completion: completion)
    }

    /// Fetch latest metric for a machine
    func fetchLatestMetric(
        machineUUID: UUID,
        timeoutInterval: TimeInterval? = nil,
        completion: @escaping (Result<MachineMetricResponse, Error>) -> Void
    ) {
        fetch(
            path: "/v1/machines/\(machineUUID.uuidString)/metrics/latest",
            timeoutInterval: timeoutInterval,
            completion: completion
        )
    }

    /// Fetch historical metrics for a machine
    func fetchMetrics(
        machineUUID: UUID,
        lastMinutes: Int? = nil,
        last: Int? = nil,
        from: String? = nil,
        since: String? = nil,
        to: String? = nil,
        completion: @escaping (Result<[MachineMetricResponse], Error>) -> Void
    ) {
        var queryItems: [URLQueryItem] = []
        if let lastMinutes {
            queryItems.append(URLQueryItem(name: "lastMinutes", value: "\(lastMinutes)"))
        }
        if let last {
            queryItems.append(URLQueryItem(name: "last", value: "\(last)"))
        }
        if let from {
            queryItems.append(URLQueryItem(name: "from", value: from))
        }
        if let since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        if let to {
            queryItems.append(URLQueryItem(name: "to", value: to))
        }
        fetch(path: "/v1/machines/\(machineUUID.uuidString)/metrics", queryItems: queryItems, completion: completion)
    }

    // MARK: - Async/Await Core Methods

    func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            fetch(path: path, queryItems: queryItems) { (result: Result<T, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    func post<Response: Decodable>(path: String, body: some Encodable) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            post(path: path, body: body) { (result: Result<Response, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    func post(path: String, body: some Encodable) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            post(path: path, body: body) { (result: Result<Data, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    func put(path: String, body: some Encodable) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            put(path: path, body: body) { (result: Result<Data, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    func delete(path: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete(path: path) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Async/Await Convenience Methods

    func fetchMachines() async throws -> [MachineEntityResponse] {
        try await fetch(path: "/v1/machines")
    }

    func createMachine(request: CreateMachineRequest) async throws -> MachineEntityResponse {
        try await post(path: "/v1/machines", body: request)
    }

    func deleteMachine(uuid: UUID) async throws {
        try await delete(path: "/v1/machines/\(uuid.uuidString)")
    }

    func updateMachine(uuid: UUID, request: UpdateMachineRequest) async throws -> Data {
        try await put(path: "/v1/machines/\(uuid.uuidString)", body: request)
    }

    func refreshAPIKey(uuid: UUID) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            refreshAPIKey(uuid: uuid) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchUserInfo() async throws -> UserInfoResponse {
        try await fetch(path: "/v1/users/me")
    }

    func fetchLatestMetric(machineUUID: UUID) async throws -> MachineMetricResponse {
        try await fetch(path: "/v1/machines/\(machineUUID.uuidString)/metrics/latest")
    }

    func fetchMetrics(
        machineUUID: UUID,
        lastMinutes: Int? = nil,
        last: Int? = nil,
        from: String? = nil,
        since: String? = nil,
        to: String? = nil
    ) async throws
        -> [MachineMetricResponse]
    {
        var queryItems: [URLQueryItem] = []
        if let lastMinutes {
            queryItems.append(URLQueryItem(name: "lastMinutes", value: "\(lastMinutes)"))
        }
        if let last {
            queryItems.append(URLQueryItem(name: "last", value: "\(last)"))
        }
        if let from {
            queryItems.append(URLQueryItem(name: "from", value: from))
        }
        if let since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        if let to {
            queryItems.append(URLQueryItem(name: "to", value: to))
        }
        return try await fetch(path: "/v1/machines/\(machineUUID.uuidString)/metrics", queryItems: queryItems)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case unauthorized
    case notFound
    case noData
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .notAuthenticated: "Not authenticated"
        case .unauthorized: "Unauthorized - please log in again"
        case .notFound: "Resource not found"
        case .noData: "No data received"
        case let .serverError(code): "Server error (\(code))"
        }
    }
}
