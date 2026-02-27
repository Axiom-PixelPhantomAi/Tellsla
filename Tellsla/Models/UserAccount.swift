import Foundation

nonisolated struct UserAccount: Codable, Identifiable, Sendable {
    let id: String
    var email: String
    var fullName: String
    var avatarURL: String?
    var isAdmin: Bool
    var subscriptionTier: SubscriptionTier
    var trialExpiresAt: Date?
    var vehicleIds: [String]
    var createdAt: Date
    var encryptionKeyHash: String?

    var isTrialActive: Bool {
        guard subscriptionTier == .trial, let expires = trialExpiresAt else { return false }
        return Date() < expires
    }

    var hasActiveSubscription: Bool {
        isAdmin || isTrialActive || subscriptionTier == .premium || subscriptionTier == .fleet
    }

    var maxVehicles: Int {
        switch subscriptionTier {
        case .trial, .premium: return 1
        case .fleet: return 10
        case .expired, .none: return 0
        }
    }
}

nonisolated enum SubscriptionTier: String, Codable, Sendable {
    case none
    case trial
    case premium
    case fleet
    case expired
}

nonisolated struct SubscriptionPlan: Identifiable, Sendable {
    let id: String
    let name: String
    let price: String
    let pricePerMonth: Double
    let description: String
    let features: [String]
    let tier: SubscriptionTier
}
