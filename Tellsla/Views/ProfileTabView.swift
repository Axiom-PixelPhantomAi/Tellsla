import SwiftUI
import LocalAuthentication

struct ProfileTabView: View {
    let appState: AppState
    @State private var showSubscription: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var showAdminAuth: Bool = false
    @State private var showTeslaConnect: Bool = false
    @State private var showCrashLogs: Bool = false
    @State private var notificationsEnabled: Bool = true
    @State private var chargeCompleteNotif: Bool = true
    @State private var sentryAlertNotif: Bool = true
    @State private var routineTriggerNotif: Bool = true
    @State private var communityReportNotif: Bool = false
    @State private var useMiles: Bool = true
    @State private var useFahrenheit: Bool = true
    @State private var biometricEnabled: Bool = false
    @State private var connectionTestResult: String?
    @State private var isTesting: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileHeader
                teslaAccountSection
                subscriptionSection
                preferencesSection
                notificationsSection
                securitySection
                tutorialsSection
                if appState.currentUser?.isAdmin == true {
                    adminSection
                }
                logoutSection
                footerSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showAdminAuth) {
            AdminAuthView(appState: appState)
        }
        .sheet(isPresented: $showTeslaConnect) {
            TeslaLoginWebView(onComplete: { success in
                showTeslaConnect = false
                if success {
                    Task { await appState.loadVehicles() }
                }
            })
        }
        .sheet(isPresented: $showCrashLogs) {
            CrashLogViewer()
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                appState.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your Tesla connection and all local data will be removed.")
        }
        .onAppear {
            biometricEnabled = appState.requireBiometric
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.fullName ?? "Tesla Owner")
                    .font(.title3.bold())
                Text(appState.currentUser?.email ?? "Connect your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(subscriptionBadge)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(subscriptionColor.opacity(0.15))
                        .foregroundStyle(subscriptionColor)
                        .clipShape(Capsule())
                    if appState.currentUser?.isAdmin == true {
                        Text("ADMIN")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var teslaAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tesla Account")
                .font(.headline)

            if appState.vehicles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No vehicles connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Connect Tesla Account") {
                        showTeslaConnect = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                ForEach(appState.vehicles) { vehicle in
                    HStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.displayName)
                                .font(.subheadline.weight(.medium))
                            Text(vehicle.vin)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(vehicle.id == appState.selectedVehicle?.id ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }

                Button {
                    showTeslaConnect = true
                } label: {
                    Label("Connect New Vehicle", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }

                Button {
                    testConnection()
                } label: {
                    HStack {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.subheadline)
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else if let result = connectionTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isTesting)
            }
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.subscriptionTier.rawValue.capitalized ?? "Free")
                        .font(.subheadline.weight(.semibold))
                    if let expires = appState.currentUser?.trialExpiresAt {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                        Text("\(max(0, days)) days remaining in trial")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Button("Manage") {
                    showSubscription = true
                }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)

            VStack(spacing: 0) {
                PreferenceToggle(title: "Distance in Miles", isOn: $useMiles, icon: "ruler")
                Divider().padding(.leading, 44)
                PreferenceToggle(title: "Temperature in °F", isOn: $useFahrenheit, icon: "thermometer")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)

            VStack(spacing: 0) {
                PreferenceToggle(title: "Charge Complete", isOn: $chargeCompleteNotif, icon: "bolt.fill")
                Divider().padding(.leading, 44)
                PreferenceToggle(title: "Sentry Alerts", isOn: $sentryAlertNotif, icon: "eye.fill")
                Divider().padding(.leading, 44)
                PreferenceToggle(title: "Routine Triggers", isOn: $routineTriggerNotif, icon: "gearshape.fill")
                Divider().padding(.leading, 44)
                PreferenceToggle(title: "Community Reports", isOn: $communityReportNotif, icon: "exclamationmark.triangle.fill")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Security")
                .font(.headline)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                        .frame(width: 24)
                    Text("Encryption")
                        .font(.subheadline)
                    Spacer()
                    Text("AES-256")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .padding(14)
                Divider().padding(.leading, 44)
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text("Auth Protocol")
                        .font(.subheadline)
                    Spacer()
                    Text("OAuth 2.0 + PKCE")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .padding(14)
                Divider().padding(.leading, 44)
                PreferenceToggle(title: "Face ID / Touch ID", isOn: $biometricEnabled, icon: "faceid")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
            .onChange(of: biometricEnabled) { _, newValue in
                appState.requireBiometric = newValue
                UserDefaults.standard.set(newValue, forKey: "requireBiometric")
            }
        }
    }

    private var tutorialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Tutorials")
                .font(.headline)

            VStack(spacing: 0) {
                TutorialLink(title: "Replay Onboarding", icon: "play.circle.fill", color: .blue) {
                    appState.replayOnboarding()
                }
                Divider().padding(.leading, 44)
                TutorialLink(title: "Navigation Guide", icon: "map.fill", color: .green) {
                    appState.showTutorial = true
                    appState.tutorialSection = "navigate"
                }
                Divider().padding(.leading, 44)
                TutorialLink(title: "Routines Guide", icon: "gearshape.2.fill", color: .purple) {
                    appState.showTutorial = true
                    appState.tutorialSection = "routines"
                }
                Divider().padding(.leading, 44)
                TutorialLink(title: "Energy Guide", icon: "bolt.fill", color: .orange) {
                    appState.showTutorial = true
                    appState.tutorialSection = "energy"
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Admin Panel")
                    .font(.headline)
                Spacer()
                Text("FULL ACCESS")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }

            VStack(spacing: 0) {
                AdminRow(title: "User Management", icon: "person.3.fill", color: .blue)
                Divider().padding(.leading, 44)
                AdminRow(title: "Analytics Dashboard", icon: "chart.bar.fill", color: .green)
                Divider().padding(.leading, 44)
                AdminRow(title: "Feature Flags", icon: "flag.fill", color: .orange)
                Divider().padding(.leading, 44)
                Button {
                    showCrashLogs = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        Text("Crash & Error Logs")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                }
                Divider().padding(.leading, 44)
                AdminRow(title: "API Rate Limits", icon: "gauge.with.dots.needle.50percent", color: .purple)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var logoutSection: some View {
        Button(role: .destructive) {
            showLogoutAlert = true
        } label: {
            HStack {
                Spacer()
                Text("Sign Out")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .clipShape(.rect(cornerRadius: 12))
        }
        .sensoryFeedback(.warning, trigger: showLogoutAlert)
    }

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Routines Connect v2.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("All data encrypted with AES-256")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var subscriptionBadge: String {
        switch appState.currentUser?.subscriptionTier {
        case .trial: return "TRIAL"
        case .premium: return "TESLA OWNER"
        case .fleet: return "FLEET"
        default: return "FREE"
        }
    }

    private var subscriptionColor: Color {
        switch appState.currentUser?.subscriptionTier {
        case .trial: return .orange
        case .premium: return .blue
        case .fleet: return .purple
        default: return .secondary
        }
    }

    private func testConnection() {
        isTesting = true
        connectionTestResult = nil
        Task {
            let (success, latency) = await AuthenticationService.shared.testConnection()
            isTesting = false
            if success {
                connectionTestResult = "Connected · \(Int(latency * 1000))ms"
            } else {
                connectionTestResult = "Failed"
            }
        }
    }
}

struct PreferenceToggle: View {
    let title: String
    @Binding var isOn: Bool
    let icon: String

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
            }
        }
        .padding(14)
    }
}

struct TutorialLink: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
        }
    }
}

struct AdminRow: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

struct CrashLogViewer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logs: [CrashLogEntry] = []

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView("No Logs", systemImage: "doc.text", description: Text("No errors or crashes recorded."))
                } else {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(logColor(log.level))
                                    .frame(width: 8, height: 8)
                                Text(log.level.rawValue.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(logColor(log.level))
                                Spacer()
                                Text(log.timestamp.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(log.message)
                                .font(.caption)
                            if let ctx = log.context {
                                Text(ctx)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Error Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        Task {
                            await CrashLogService.shared.clearLogs()
                            logs = []
                        }
                    }
                }
            }
            .task {
                logs = await CrashLogService.shared.getLogs()
            }
        }
    }

    private func logColor(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .orange
        case .critical: return .red
        }
    }
}
