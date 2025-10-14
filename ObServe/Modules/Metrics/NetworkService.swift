import Foundation

class NetworkService {
    let ip: String
    let port: String
    let basePath: String
    private let apiKey: String

    init(ip: String, port: String, basePath: String = "", apiKey: String) {
        self.ip = ip
        self.port = port
        self.basePath = basePath
        self.apiKey = apiKey
    }
    
    private var baseURL: String {
        return "http://\(ip):\(port)\(basePath)"
    }
    
    func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
    
    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        return request
    }
    
    func checkHealth(completion: @escaping (Bool) -> Void) {
        // Build URL without the base path for health-check endpoint
        let healthURL = "http://\(ip):\(port)/health-check"
        guard let url = URL(string: healthURL) else {
            completion(false)
            return
        }

        var request = createRequest(for: url)
        request.timeoutInterval = 5.0 // 5 second timeout

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            // Silently treat any error (including timeout) as server offline
            if error != nil {
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let isHealthy = httpResponse.statusCode == 200
                completion(isHealthy)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    func fetch<T: Decodable>(endpoint: String, queryItems: [URLQueryItem] = [], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(endpoint: endpoint, queryItems: queryItems) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        let request = createRequest(for: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch let decodingError as DecodingError {
                let detailedError = self.createDetailedError(decodingError, endpoint: endpoint, responseType: String(describing: T.self), rawData: data)
                completion(.failure(detailedError))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    private func createDetailedError(_ error: DecodingError, endpoint: String, responseType: String, rawData: Data) -> NSError {
        var errorMessage = "Decoding error for \(responseType) at endpoint '\(endpoint)':\n"

        // Add raw response preview
        if let rawString = String(data: rawData, encoding: .utf8) {
            let preview = rawString.prefix(200)
            errorMessage += "Raw response: '\(preview)'\n\n"
        }

        switch error {
        case .typeMismatch(let type, let context):
            errorMessage += "Type mismatch at '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'\n"
            errorMessage += "Expected type: \(type)\n"
            errorMessage += "Debug description: \(context.debugDescription)"

        case .valueNotFound(let type, let context):
            errorMessage += "Value not found at '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'\n"
            errorMessage += "Expected type: \(type)\n"
            errorMessage += "Debug description: \(context.debugDescription)"

        case .keyNotFound(let key, let context):
            errorMessage += "Key '\(key.stringValue)' not found\n"
            errorMessage += "Expected location: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))\n"
            errorMessage += "Debug description: \(context.debugDescription)"

        case .dataCorrupted(let context):
            errorMessage += "Data corrupted at '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'\n"
            errorMessage += "Debug description: \(context.debugDescription)"

        @unknown default:
            errorMessage += "Unknown decoding error: \(error.localizedDescription)"
        }

        return NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }

    func fetchPlainValue<T: LosslessStringConvertible>(endpoint: String, queryItems: [URLQueryItem] = [], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(endpoint: endpoint, queryItems: queryItems) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        let request = createRequest(for: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            // Try to parse the data as a plain text value
            guard let stringValue = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                let errorMsg = "Failed to decode response data as UTF-8 string at endpoint '\(endpoint)'"
                completion(.failure(NSError(domain: "ParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }

            // Try converting to expected type
            if let value = T(stringValue) {
                completion(.success(value))
            } else {
                let errorMsg = "Failed to parse plain value at endpoint '\(endpoint)'. Expected type: \(T.self), received value: '\(stringValue)'"
                completion(.failure(NSError(domain: "ParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
            }
        }
        task.resume()
    }
}
