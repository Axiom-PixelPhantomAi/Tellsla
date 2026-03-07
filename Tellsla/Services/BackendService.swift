import Foundation

actor BackendService {
    static let shared = BackendService()
    
    private let baseURL = URL(string: ProcessInfo.processInfo.environment["RORK_BACKEND_URL"] ?? "https://api.rork.app")!
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Auth
    func register(email: String, deviceToken: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/register",
            method: "POST",
            body: ["email": email, "deviceToken": deviceToken]
        )
    }
    
    func login(email: String, deviceToken: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: ["email": email, "deviceToken": deviceToken]
        )
    }
    
    // MARK: - Trip Logging
    func logTrip(startLat: Double, startLon: Double, endLat: Double, endLon: Double, 
                 distanceMiles: Double, energyKwh: Double, efficiency: Double) async throws -> TripResponse {
        let body: [String: Any] = [
            "startLat": startLat,
            "startLon": startLon,
            "endLat": endLat,
            "endLon": endLon,
            "distanceMiles": distanceMiles,
            "energyKwh": energyKwh,
            "efficiency": efficiency
        ]
        return try await authenticatedRequest(endpoint: "/trips", method: "POST", body: body)
    }
    
    // MARK: - Community Reports
    func submitReport(lat: Double, lon: Double, type: String, message: String) async throws -> ReportResponse {
        let body: [String: Any] = [
            "lat": lat,
            "lon": lon,
            "type": type,
            "message": message
        ]
        return try await authenticatedRequest(endpoint: "/reports", method: "POST", body: body)
    }
    
    func getNearbyReports(lat: Double, lon: Double, radius: Double = 10) async throws -> [CommunityReport] {
        let endpoint = "/reports/nearby?lat=\(lat)&lon=\(lon)&radius=\(radius)"
        let response: [ReportData] = try await authenticatedRequest(endpoint: endpoint, method: "GET")
        return response.map { $0.toCommunityReport() }
    }
    
    // MARK: - Private Helpers
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw BackendError.serverError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func authenticatedRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let token = KeychainService.load(.accessToken) else {
            throw BackendError.notAuthenticated
        }
        
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw BackendError.serverError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Types
nonisolated enum BackendError: Error, LocalizedError {
    case invalidURL
    case serverError
    case notAuthenticated
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError: return "Server error. Try again later."
        case .notAuthenticated: return "Not authenticated. Please login."
        case .decodingError: return "Failed to decode response."
        }
    }
}

nonisolated struct AuthResponse: Codable {
    let success: Bool
    let userId: String
    let token: String
}

nonisolated struct TripResponse: Codable {
    let success: Bool
    let tripId: String
}

nonisolated struct ReportResponse: Codable {
    let success: Bool
    let reportId: String
}

nonisolated struct ReportData: Codable {
    let id: String
    let userId: String
    let lat: Double
    let lon: Double
    let type: String
    let message: String
    let timestamp: String
    
    func toCommunityReport() -> CommunityReport {
        CommunityReport(
            id: id,
            type: ReportType(rawValue: type) ?? .roadHazard,
            latitude: lat,
            longitude: lon,
            description: message,
            reporterDisplayName: userId,
            upvotes: 0,
            downvotes: 0,
            isVerified: false,
            createdAt: ISO8601DateFormatter().date(from: timestamp) ?? Date()
        )
    }
}
