import Foundation

class NetworkService {
    let ip: String
    let port: String
    let basePath: String
    
    init(ip: String, port: String, basePath: String = "/v1") {
        self.ip = ip
        self.port = port
        self.basePath = basePath
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
    
    func fetch<T: Decodable>(endpoint: String, queryItems: [URLQueryItem] = [], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(endpoint: endpoint, queryItems: queryItems) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
