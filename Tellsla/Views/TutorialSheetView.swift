import SwiftUI

struct TutorialSheetView: View {
    let section: String
    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false

    private var tutorialPage: TutorialPage? {
        TutorialData.onboardingPages.first(where: { $0.id == section })
    }

    private var featureTutorial: [TutorialFeature]? {
        TutorialData.featureTutorials[section]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let page = tutorialPage {
                        pageTutorialContent(page)
                    } else if let features = featureTutorial {
                        featureTutorialContent(features)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(sectionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appeared = true
            }
        }
    }

    private func pageTutorialContent(_ page: TutorialPage) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: page.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(accentColor(for: page.accentColorName))
                    .symbolEffect(.bounce, value: appeared)

                Text(page.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.title.bold())

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }

            Text("Features")
                .font(.title3.bold())

            ForEach(Array(page.features.enumerated()), id: \.element.id) { index, feature in
                TutorialFeatureRow(feature: feature, index: index + 1, color: accentColor(for: page.accentColorName), appeared: appeared)
            }

            howItWorksSection(for: page.id)
        }
    }

    private func featureTutorialContent(_ features: [TutorialFeature]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How It Works")
                .font(.title.bold())

            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                TutorialFeatureRow(feature: feature, index: index + 1, color: .blue, appeared: appeared)
            }
        }
    }

    @ViewBuilder
    private func howItWorksSection(for sectionId: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.title3.bold())

            switch sectionId {
            case "navigate":
                TutorialStepCard(step: 1, title: "Set Your Destination", description: "Search for a place or tap a quick destination like Home, Work, or Nearest Charger.", icon: "magnifyingglass")
                TutorialStepCard(step: 2, title: "Review Trip Estimate", description: "See energy cost, battery at arrival, and whether you need a charging stop — all before you leave.", icon: "chart.bar.fill")
                TutorialStepCard(step: 3, title: "Smart Route Selection", description: "The system factors in elevation, speed limits, weather, and your driving style for accurate range predictions.", icon: "arrow.triangle.branch")
                TutorialStepCard(step: 4, title: "Live Navigation", description: "Turn-by-turn directions with real-time battery impact per segment and automatic rerouting through chargers.", icon: "location.fill")

            case "routines":
                TutorialStepCard(step: 1, title: "Choose Triggers", description: "Combine time of day, location arrival/departure, battery level, temperature, and more.", icon: "bolt.fill")
                TutorialStepCard(step: 2, title: "Set Actions", description: "Pre-condition your cabin, start charging, navigate, lock, send notifications — chain multiple actions.", icon: "list.bullet")
                TutorialStepCard(step: 3, title: "AI Learns You", description: "After a week, the system detects your driving patterns and suggests new routines automatically.", icon: "brain")
                TutorialStepCard(step: 4, title: "Runs Automatically", description: "When conditions match, your routine fires. You get a notification and can see the results in real time.", icon: "checkmark.circle.fill")

            case "energy":
                TutorialStepCard(step: 1, title: "Connect Your Utility", description: "Enter your electricity provider to get real-time pricing and time-of-use rates.", icon: "building.2.fill")
                TutorialStepCard(step: 2, title: "Solar Awareness", description: "If you have a Powerwall or solar panels, the system tracks production and optimizes charging accordingly.", icon: "sun.max.fill")
                TutorialStepCard(step: 3, title: "Smart Scheduling", description: "Charging automatically shifts to the cheapest time window — saving you up to 60% on electricity costs.", icon: "clock.arrow.2.circlepath")
                TutorialStepCard(step: 4, title: "Fleet Balancing", description: "Multiple Teslas? Charging staggers automatically to stay under your electrical panel capacity.", icon: "bolt.horizontal.fill")

            case "community":
                TutorialStepCard(step: 1, title: "Report Hazards", description: "Tap to report potholes, road hazards, police, construction, or broken chargers in seconds.", icon: "exclamationmark.triangle.fill")
                TutorialStepCard(step: 2, title: "See Live Reports", description: "Reports from other Tesla drivers appear on your map with reliability scores based on community votes.", icon: "map.fill")
                TutorialStepCard(step: 3, title: "Show Your Tesla", description: "Optionally make your vehicle visible on the community map. Great for meetups and caravan coordination.", icon: "car.fill")
                TutorialStepCard(step: 4, title: "Caravan Mode", description: "Sync navigation with friends for road trips. Everyone sees the group on the map with stop signals.", icon: "point.3.connected.trianglepath.dotted")

            case "vehicle":
                TutorialStepCard(step: 1, title: "Remote Controls", description: "Lock, unlock, flash lights, honk, open frunk/trunk — all from the app with haptic confirmation.", icon: "hand.tap.fill")
                TutorialStepCard(step: 2, title: "Predictive Maintenance", description: "AI analyzes your driving patterns, road conditions, and mileage to predict per-component wear.", icon: "wrench.and.screwdriver")
                TutorialStepCard(step: 3, title: "Smart Sentry", description: "Computer vision filters Sentry events — only real threats send notifications. No more false alarms.", icon: "eye.fill")
                TutorialStepCard(step: 4, title: "Full Diagnostics", description: "Tire pressures, temperatures, efficiency stats, software version — everything at a glance.", icon: "gauge.with.dots.needle.50percent")

            default:
                EmptyView()
            }
        }
    }

    private var sectionTitle: String {
        switch section {
        case "navigate": return "Navigation Guide"
        case "routines": return "Routines Guide"
        case "energy": return "Energy Guide"
        case "community": return "Community Guide"
        case "vehicle": return "Vehicle Guide"
        case "sentry": return "Smart Sentry"
        case "fleet": return "Fleet Management"
        default: return "Tutorial"
        }
    }

    private func accentColor(for name: String) -> Color {
        switch name {
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "cyan": return .cyan
        case "red": return .red
        default: return .blue
        }
    }
}

struct TutorialFeatureRow: View {
    let feature: TutorialFeature
    let index: Int
    let color: Color
    let appeared: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.spring(response: 0.5).delay(Double(index) * 0.08), value: appeared)
    }
}

struct TutorialStepCard: View {
    let step: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text("\(step)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
