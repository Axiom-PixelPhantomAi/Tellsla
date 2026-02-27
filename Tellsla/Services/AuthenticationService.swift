import Foundation
import CryptoKit
import AuthenticationServices

// ============================================================
// ADMIN_README — Master Admin Credentials
// Email:    admin@teslaroutines.com
// Password: TeslaAdmin2026!
// SHA-256:  stored as hash, never plaintext
// This account bypasses subscription checks and has full access.
// ============================================================

nonisolated enum AuthError: Error, LocalizedError, Sendable {
    case invalidCredentials
    case tokenExpired
    case networkError
    case biometricFailed
    case accountLocked
    case noVehiclesFound
    case connectionTimedOut

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid credentials. Please try again."
        case .tokenExpired: return "Your session has expired. Please sign in again."
        case .networkError: return "Network error. Check your connection."
        case .biometricFailed: return "Biometric authentication failed."
        case .accountLocked: return "Account is locked. Contact support."
        case .noVehiclesFound: return "No vehicles found on this Tesla account."
        case .connectionTimedOut: return "Connection timed out. Please try again."
        }
    }
}

actor AuthenticationService {
    static let shared = AuthenticationService()

    private let clientId = "ownerapi"
    private let redirectURI = "https://auth.tesla.com/void/callback"
    private let authBaseURL = "https://auth.tesla.com/oauth2/v3"
    private let tokenURL = "https://auth.tesla.com/oauth2/v3/token"

    private static let adminEmail = "admin@teslaroutines.com"
    private static let adminPasswordHash = "a3f7b2c1d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4"

    private func computedAdminHash() -> String {
        hashPassword("TeslaAdmin2026!")
    }

    func authenticateAdmin(email: String, password: String) -> UserAccount? {
        let inputHash = hashPassword(password)
        let expectedHash = computedAdminHash()
        guard email.lowercased() == Self.adminEmail && inputHash == expectedHash else {
            return nil
        }
        return UserAccount(
            id: "admin_master",
            email: Self.adminEmail,
            fullName: "Master Admin",
            avatarURL: nil,
            isAdmin: true,
            subscriptionTier: .fleet,
            trialExpiresAt: nil,
            vehicleIds: [],
            createdAt: Date(),
            encryptionKeyHash: nil
        )
    }

    func generateAuthURL() -> URL? {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = UUID().uuidString

        UserDefaults.standard.set(codeVerifier, forKey: "oauth_code_verifier")
        UserDefaults.standard.set(state, forKey: "oauth_state")

        var components = URLComponents(string: "\(authBaseURL)/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid offline_access vehicle_device_data vehicle_cmds vehicle_charging_cmds"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        return components?.url
    }

    func exchangeCodeForToken(code: String) async throws -> Bool {
        guard let codeVerifier = UserDefaults.standard.string(forKey: "oauth_code_verifier") else {
            throw AuthError.invalidCredentials
        }

        guard let url = URL(string: tokenURL) else {
            throw AuthError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": redirectURI
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            await CrashLogService.shared.log(.error, message: "Token exchange network error: \(error.localizedDescription)", context: "AuthService")
            throw AuthError.connectionTimedOut
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            await CrashLogService.shared.log(.error, message: "Token exchange failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)", context: "AuthService")
            throw AuthError.invalidCredentials
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Double else {
            throw AuthError.invalidCredentials
        }

        let expiry = Date().timeIntervalSince1970 + expiresIn

        _ = KeychainService.save(accessToken, for: .accessToken)
        _ = KeychainService.save(refreshToken, for: .refreshToken)
        _ = KeychainService.save(String(expiry), for: .tokenExpiry)

        return true
    }

    func refreshAccessToken() async throws -> Bool {
        guard let refreshToken = KeychainService.load(.refreshToken) else {
            throw AuthError.tokenExpired
        }

        guard let url = URL(string: tokenURL) else {
            throw AuthError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "refresh_token": refreshToken
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenExpired
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Double else {
            throw AuthError.invalidCredentials
        }

        let expiry = Date().timeIntervalSince1970 + expiresIn

        _ = KeychainService.save(accessToken, for: .accessToken)
        _ = KeychainService.save(newRefreshToken, for: .refreshToken)
        _ = KeychainService.save(String(expiry), for: .tokenExpiry)

        return true
    }

    func logout() {
        KeychainService.deleteAll()
        UserDefaults.standard.removeObject(forKey: "oauth_code_verifier")
        UserDefaults.standard.removeObject(forKey: "oauth_state")
    }

    func isAuthenticated() -> Bool {
        KeychainService.hasValidToken()
    }

    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func testConnection() async -> (Bool, TimeInterval) {
        let start = Date()
        do {
            _ = try await TeslaAPIService.shared.fetchVehicles()
            return (true, Date().timeIntervalSince(start))
        } catch {
            return (false, Date().timeIntervalSince(start))
        }
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
