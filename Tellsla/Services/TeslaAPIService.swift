import Foundation

nonisolated enum TeslaAPIError: Error, Sendable {
    case notAuthenticated
    case invalidResponse
    case rateLimited
    case vehicleAsleep
    case networkError(String)
    case serverError(Int)
    case decodingError
}

actor TeslaAPIService {
    static let shared = TeslaAPIService()
    private let baseURL = "https://fleet-api.prd.na.vn.cloud.tesla.com"
    private let authURL = "https://auth.tesla.com"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        self.session = URLSession(configuration: config)
    }

    private func authHeaders() throws -> [String: String] {
        guard let token = KeychainService.load(.accessToken) else {
            throw TeslaAPIError.notAuthenticated
        }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    func fetchVehicles() async throws -> [Vehicle] {
        let data = try await request(endpoint: "/api/1/vehicles")
        let response = try JSONDecoder.tesla.decode(TeslaListResponse<VehicleResponse>.self, from: data)
        return response.response.map { $0.toVehicle() }
    }

    func fetchVehicleData(vehicleId: String) async throws -> Vehicle {
        let data = try await request(endpoint: "/api/1/vehicles/\(vehicleId)/vehicle_data")
        let response = try JSONDecoder.tesla.decode(TeslaSingleResponse<VehicleDataResponse>.self, from: data)
        return response.response.toVehicle()
    }

    func wakeUp(vehicleId: String) async throws {
        _ = try await request(endpoint: "/api/1/vehicles/\(vehicleId)/wake_up", method: "POST")
    }

    func sendCommand(vehicleId: String, command: String, body: [String: Any]? = nil) async throws {
        var bodyData: Data?
        if let body = body {
            bodyData = try JSONSerialization.data(withJSONObject: body)
        }
        _ = try await request(
            endpoint: "/api/1/vehicles/\(vehicleId)/command/\(command)",
            method: "POST",
            body: bodyData
        )
    }

    func setClimateTemp(vehicleId: String, tempCelsius: Double) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "set_temps", body: [
            "driver_temp": tempCelsius,
            "passenger_temp": tempCelsius
        ])
    }

    func startClimate(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "auto_conditioning_start")
    }

    func stopClimate(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "auto_conditioning_stop")
    }

    func fetchNearbySuperchargers(latitude: Double, longitude: Double, radiusMiles: Double = 50) async throws -> [Supercharger] {
        // Mock implementation - In production, query Tesla Fleet API or third-party DB
        return mockSuperchargers(near: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), radius: radiusMiles)
    }

    private func mockSuperchargers(near center: CLLocationCoordinate2D, radius: Double) -> [Supercharger] {
        let mockChargers = [
            Supercharger(id: "sc_001", name: "Golden Gate Park", address: "San Francisco, CA", latitude: 37.7694, longitude: -122.4862, totalStalls: 12, availableStalls: 7, maxPowerKW: 250, pricePerKWh: 0.35, amenities: [.restrooms, .food], status: .operational, distanceMiles: 3.2, estimatedWaitMinutes: 12),
            Supercharger(id: "sc_002", name: "Walnut Creek", address: "Walnut Creek, CA", latitude: 37.8687, longitude: -122.3005, totalStalls: 20, availableStalls: 15, maxPowerKW: 250, pricePerKWh: 0.32, amenities: [.restrooms, .wifi, .shopping], status: .operational, distanceMiles: 15.4, estimatedWaitMinutes: 5),
            Supercharger(id: "sc_003", name: "San Jose Airport", address: "San Jose, CA", latitude: 37.6213, longitude: -122.0750, totalStalls: 30, availableStalls: 8, maxPowerKW: 250, pricePerKWh: 0.38, amenities: [.restrooms, .lodging, .wifi], status: .congested, distanceMiles: 42.1, estimatedWaitMinutes: 28)
        ]
        return mockChargers.filter { sc in haversineDistance(from: center, to: sc.coordinate) <= radius }
    }

    private func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let latDiff = (to.latitude - from.latitude) * .pi / 180
        let lonDiff = (to.longitude - from.longitude) * .pi / 180
        let a = sin(latDiff / 2) * sin(latDiff / 2) + cos(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180) * sin(lonDiff / 2) * sin(lonDiff / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return 3959 * c
    }

    func lockDoors(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "door_lock")
    }

    func unlockDoors(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "door_unlock")
    }

    func setSentryMode(vehicleId: String, enabled: Bool) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "set_sentry_mode", body: ["on": enabled])
    }

    func setChargeLimit(vehicleId: String, percent: Int) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "set_charge_limit", body: ["percent": percent])
    }

    func startCharging(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "charge_start")
    }

    func stopCharging(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "charge_stop")
    }

    func flashLights(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "flash_lights")
    }

    func honkHorn(vehicleId: String) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "honk_horn")
    }

    func openTrunk(vehicleId: String, which: String = "rear") async throws {
        try await sendCommand(vehicleId: vehicleId, command: "actuate_trunk", body: ["which_trunk": which])
    }

    func shareDestination(vehicleId: String, latitude: Double, longitude: Double) async throws {
        try await sendCommand(vehicleId: vehicleId, command: "share", body: [
            "type": "share_ext_content_raw",
            "value": ["android.intent.extra.TEXT": "\(latitude),\(longitude)"],
            "locale": "en-US",
            "timestamp_ms": Int(Date().timeIntervalSince1970 * 1000)
        ])
    }

    func fetchNearbySuperchargers(latitude: Double, longitude: Double) async throws -> [Supercharger] {
        let data = try await request(
            endpoint: "/api/1/vehicles/charging_sites?latitude=\(latitude)&longitude=\(longitude)&count=20"
        )
        let response = try JSONDecoder.tesla.decode(TeslaSingleResponse<ChargingSitesResponse>.self, from: data)
        return response.response.superchargers.map { $0.toSupercharger() }
    }

    private func request(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw TeslaAPIError.networkError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody = body

        let headers = try authHeaders()
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeslaAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299: return data
        case 401: throw TeslaAPIError.notAuthenticated
        case 408: throw TeslaAPIError.vehicleAsleep
        case 429: throw TeslaAPIError.rateLimited
        default: throw TeslaAPIError.serverError(httpResponse.statusCode)
        }
    }
}

extension JSONDecoder {
    static nonisolated let tesla: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

nonisolated struct TeslaListResponse<T: Codable & Sendable>: Codable, Sendable {
    let response: [T]
    let count: Int?
}

nonisolated struct TeslaSingleResponse<T: Codable & Sendable>: Codable, Sendable {
    let response: T
}

nonisolated struct VehicleResponse: Codable, Sendable {
    let id: Int
    let vehicleId: Int
    let vin: String
    let displayName: String?
    let state: String?

    func toVehicle() -> Vehicle {
        Vehicle(
            id: String(id),
            displayName: displayName ?? "My Tesla",
            vin: vin,
            model: .model3,
            year: 2024,
            color: "White",
            batteryLevel: 0,
            batteryRange: 0,
            isCharging: false,
            chargingState: .disconnected,
            chargeLimit: 80,
            isLocked: true,
            isClimateOn: false,
            interiorTemp: 20,
            exteriorTemp: 20,
            odometer: 0,
            softwareVersion: "",
            sentryModeActive: false,
            latitude: 0,
            longitude: 0,
            heading: 0,
            speed: 0,
            shiftState: nil,
            tirePressures: TirePressures(frontLeft: 42, frontRight: 42, rearLeft: 42, rearRight: 42),
            lastSeen: Date()
        )
    }
}

nonisolated struct VehicleDataResponse: Codable, Sendable {
    let id: Int
    let vehicleId: Int?
    let vin: String?
    let displayName: String?

    func toVehicle() -> Vehicle {
        Vehicle(
            id: String(id),
            displayName: displayName ?? "My Tesla",
            vin: vin ?? "",
            model: .model3,
            year: 2024,
            color: "White",
            batteryLevel: 0,
            batteryRange: 0,
            isCharging: false,
            chargingState: .disconnected,
            chargeLimit: 80,
            isLocked: true,
            isClimateOn: false,
            interiorTemp: 20,
            exteriorTemp: 20,
            odometer: 0,
            softwareVersion: "",
            sentryModeActive: false,
            latitude: 0,
            longitude: 0,
            heading: 0,
            speed: 0,
            shiftState: nil,
            tirePressures: TirePressures(frontLeft: 42, frontRight: 42, rearLeft: 42, rearRight: 42),
            lastSeen: Date()
        )
    }
}

nonisolated struct ChargingSitesResponse: Codable, Sendable {
    let superchargers: [SuperchargerResponse]
}

nonisolated struct SuperchargerResponse: Codable, Sendable {
    let location: LocationResponse
    let name: String
    let availableStalls: Int?
    let totalStalls: Int?

    func toSupercharger() -> Supercharger {
        Supercharger(
            id: name,
            name: name,
            address: "",
            latitude: location.lat,
            longitude: location.long,
            totalStalls: totalStalls ?? 0,
            availableStalls: availableStalls ?? 0,
            maxPowerKW: 250,
            pricePerKWh: nil,
            amenities: [],
            status: .operational,
            distanceMiles: nil,
            estimatedWaitMinutes: nil
        )
    }
}

nonisolated struct LocationResponse: Codable, Sendable {
    let lat: Double
    let long: Double
}
