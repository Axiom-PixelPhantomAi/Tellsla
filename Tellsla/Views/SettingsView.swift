import SwiftUI

struct SettingsView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Settings") {
                    Toggle("Push Notifications", isOn: .constant(true))
                    Toggle("Smart Charging", isOn: .constant(true))
                    Toggle("Haptic Feedback", isOn: .constant(true))
                }

                Section {
                    VStack(spacing: 4) {
                        Text("Routines Connect v2.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("All data encrypted with AES-256")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AdminAuthView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAuthenticated: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            if isAuthenticated {
                AdminDashboardView(appState: appState)
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Admin Access")
                        .font(.title2.bold())
                    Text("Enter the master admin credentials.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 40)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Authenticate") {
                        Task {
                            if let user = await AuthenticationService.shared.authenticateAdmin(email: email, password: password) {
                                appState.currentUser = user
                                isAuthenticated = true
                            } else {
                                errorMessage = "Invalid credentials"
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct AdminDashboardView: View {
    let appState: AppState
    @State private var showCrashLogs: Bool = false

    var body: some View {
        List {
            if appState.currentUser?.isAdmin == true {
                Section {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(.red)
                        Text("Master Admin Account — Full Access")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.red.opacity(0.08))
                }
            }

            Section("Admin Controls") {
                Label("All Vehicles", systemImage: "car.2.fill")
                Label("User Management", systemImage: "person.3.fill")
                Label("Subscription Override", systemImage: "creditcard.fill")
                Label("System Diagnostics", systemImage: "wrench.and.screwdriver")
                Label("API Rate Limits", systemImage: "gauge.with.dots.needle.50percent")
                Label("Feature Flags", systemImage: "flag.fill")
                Button {
                    showCrashLogs = true
                } label: {
                    Label("Error & Crash Logs", systemImage: "exclamationmark.triangle.fill")
                }
            }

            Section("System Status") {
                HStack {
                    Text("API Status")
                    Spacer()
                    Text("Connected")
                        .foregroundStyle(.green)
                }
                HStack {
                    Text("Active Users")
                    Spacer()
                    Text("—")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Server Version")
                    Spacer()
                    Text("2.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCrashLogs) {
            CrashLogViewer()
        }
    }
}
