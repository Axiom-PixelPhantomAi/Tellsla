import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = "premium"

    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "premium",
            name: "Tesla Owner",
            price: "$3.99/mo",
            pricePerMonth: 3.99,
            description: "Full access for one Tesla",
            features: [
                "Intelligent navigation with energy routing",
                "Unlimited smart routines & AI suggestions",
                "Community road reports & map",
                "Predictive maintenance alerts",
                "Smart Sentry Mode filtering",
                "Solar & time-of-use charging optimization",
            ],
            tier: .premium
        ),
        SubscriptionPlan(
            id: "fleet",
            name: "Fleet Plan",
            price: "$3.99 + $2/vehicle",
            pricePerMonth: 5.99,
            description: "Multi-Tesla household coordination",
            features: [
                "Everything in Tesla Owner",
                "Up to 10 vehicles per account",
                "Fleet charging coordination",
                "Vehicle trip assignment AI",
                "Staggered charge scheduling",
                "Family sharing & permissions",
            ],
            tier: .fleet
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.car.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        Text("Routines Connect Pro")
                            .font(.title2.bold())
                        Text("7-day free trial · Cancel anytime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    ForEach(plans) { plan in
                        PlanCard(plan: plan, isSelected: selectedPlan == plan.id) {
                            withAnimation(.snappy) {
                                selectedPlan = plan.id
                            }
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Start Free Trial")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        Text("After your 7-day free trial, you'll be charged \(plans.first(where: { $0.id == selectedPlan })?.price ?? "$3.99/mo"). Cancel anytime in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button("Terms of Service") {}
                                .font(.caption2)
                            Button("Privacy Policy") {}
                                .font(.caption2)
                            Button("Restore Purchase") {}
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(plan.price)
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }

                Text(plan.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.06) : Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
        }
    }
}
