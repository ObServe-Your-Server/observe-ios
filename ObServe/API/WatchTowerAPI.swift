import Foundation

class WatchTowerAPI {
    static let shared = WatchTowerAPI()

    private let baseURL = "https://watch-tower.marco-brandt.com"
    private weak var authManager: AuthenticationManager?

    private init() {}

    func configure(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    // MARK: - Generic Request Helpers

    private func createRequest(for url: URL, method: String = "GET") -> URLRequest? {
        guard let authManager = authManager else {
            print("WatchTowerAPI: AuthenticationManager not configured")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(authManager.bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    // MARK: - GET

    func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = [], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(path: path, queryItems: queryItems) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        guard let request = createRequest(for: url) else {
            completion(.failure(APIError.notAuthenticated))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                if httpResponse.statusCode == 404 {
                    completion(.failure(APIError.notFound))
                    return
                }
                if httpResponse.statusCode >= 400 {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    return
                }
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                if let rawString = String(data: data, encoding: .utf8) {
                    print("WatchTowerAPI: Decoding failed for \(T.self). Raw: \(rawString.prefix(300))")
                }
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - POST

    func post<Body: Encodable, Response: Decodable>(path: String, body: Body, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let url = buildURL(path: path) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        guard var request = createRequest(for: url, method: "POST") else {
            completion(.failure(APIError.notAuthenticated))
            return
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                if httpResponse.statusCode >= 400 {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    return
                }
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(Response.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// POST that returns raw Data (for endpoints with empty/untyped response bodies)
    func post<Body: Encodable>(path: String, body: Body, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = buildURL(path: path) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        guard var request = createRequest(for: url, method: "POST") else {
            completion(.failure(APIError.notAuthenticated))
            return
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                if httpResponse.statusCode >= 400 {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    return
                }
            }

            completion(.success(data ?? Data()))
        }.resume()
    }

    // MARK: - PUT

    func put<Body: Encodable>(path: String, body: Body, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = buildURL(path: path) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        guard var request = createRequest(for: url, method: "PUT") else {
            completion(.failure(APIError.notAuthenticated))
            return
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                if httpResponse.statusCode >= 400 {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    return
                }
            }

            completion(.success(data ?? Data()))
        }.resume()
    }

    // MARK: - DELETE

    func delete(path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = buildURL(path: path) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        guard let request = createRequest(for: url, method: "DELETE") else {
            completion(.failure(APIError.notAuthenticated))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                if httpResponse.statusCode >= 400 {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    return
                }
            }

            completion(.success(()))
        }.resume()
    }

    // MARK: - Convenience Methods

    /// Fetch all machines for the authenticated user
    func fetchMachines(completion: @escaping (Result<[MachineEntityResponse], Error>) -> Void) {
        fetch(path: "/v1/machines", completion: completion)
    }

    /// Create a new machine
    func createMachine(request: CreateMachineRequest, completion: @escaping (Result<MachineEntityResponse, Error>) -> Void) {
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

    /// Fetch latest metric for a machine
    func fetchLatestMetric(machineUUID: UUID, completion: @escaping (Result<MachineMetricResponse, Error>) -> Void) {
        fetch(path: "/v1/machines/\(machineUUID.uuidString)/metrics/latest", completion: completion)
    }

    /// Fetch historical metrics for a machine
    func fetchMetrics(machineUUID: UUID, lastMinutes: Int? = nil, last: Int? = nil, completion: @escaping (Result<[MachineMetricResponse], Error>) -> Void) {
        var queryItems: [URLQueryItem] = []
        if let lastMinutes = lastMinutes {
            queryItems.append(URLQueryItem(name: "lastMinutes", value: "\(lastMinutes)"))
        }
        if let last = last {
            queryItems.append(URLQueryItem(name: "last", value: "\(last)"))
        }
        fetch(path: "/v1/machines/\(machineUUID.uuidString)/metrics", queryItems: queryItems, completion: completion)
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
        case .invalidURL: return "Invalid URL"
        case .notAuthenticated: return "Not authenticated"
        case .unauthorized: return "Unauthorized - please log in again"
        case .notFound: return "Resource not found"
        case .noData: return "No data received"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}
