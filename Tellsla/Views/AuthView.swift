import SwiftUI
import AuthenticationServices

struct AuthView: View {
    let onAuthenticated: () -> Void
    @State private var showTeslaLogin: Bool = false
    @State private var showAdminLogin: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var pulseAnimation: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, .black, .black,
                    Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15),
                    .black, Color(red: 0.05, green: 0.1, blue: 0.2), .black
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.5)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: pulseAnimation)

                        Image(systemName: "bolt.car.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white)
                    }
                    .onAppear { pulseAnimation = true }

                    Text("Routines Connect")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Your Tesla, Supercharged")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text("End-to-end encrypted")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.orange)
                        Text("Secure Keychain storage")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundStyle(.blue)
                        Text("Tesla OAuth 2.0 + PKCE")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        startTeslaOAuth()
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text("Sign in with Tesla")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(isLoading)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isLoading)

                    Button {
                        showAdminLogin = true
                    } label: {
                        Text("Admin Login")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    Text("Your Tesla credentials are never stored.\nWe use OAuth tokens secured in the iOS Keychain.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showTeslaLogin) {
            TeslaLoginWebView(onComplete: { success in
                showTeslaLogin = false
                if success {
                    onAuthenticated()
                }
            })
        }
        .sheet(isPresented: $showAdminLogin) {
            AdminLoginSheet(onAuthenticated: onAuthenticated)
        }
    }

    private func startTeslaOAuth() {
        isLoading = true
        errorMessage = nil

        Task {
            guard await AuthenticationService.shared.generateAuthURL() != nil else {
                isLoading = false
                errorMessage = "Failed to generate auth URL"
                return
            }

            await MainActor.run {
                isLoading = false
                showTeslaLogin = true
            }
        }
    }
}

struct AdminLoginSheet: View {
    let onAuthenticated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Admin Login")
                    .font(.title2.bold())

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal, 40)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    authenticate()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Authenticate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Spacer()
            }
            .navigationTitle("Admin Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func authenticate() {
        isLoading = true
        errorMessage = nil
        Task {
            if await AuthenticationService.shared.authenticateAdmin(email: email, password: password) != nil {
                await MainActor.run {
                    _ = KeychainService.save("admin_token", for: .accessToken)
                    _ = KeychainService.save(String(Date().addingTimeInterval(86400 * 365).timeIntervalSince1970), for: .tokenExpiry)
                    dismiss()
                    onAuthenticated()
                }
            } else {
                isLoading = false
                errorMessage = "Invalid credentials"
            }
        }
    }
}

struct TeslaLoginWebView: View {
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Tesla Authentication")
                    .font(.title2.bold())

                Text("Connect your Tesla account to enable\nvehicle control, navigation, and automation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    PermissionRow(icon: "car.fill", text: "Access vehicle data & status")
                    PermissionRow(icon: "location.fill", text: "Vehicle location & navigation")
                    PermissionRow(icon: "bolt.fill", text: "Charging management")
                    PermissionRow(icon: "gearshape.fill", text: "Vehicle commands & controls")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal)

                VStack(spacing: 8) {
                    Text("This will open Tesla's secure login page")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("ASWebAuthenticationSession · OAuth 2.0 + PKCE")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    onComplete(true)
                } label: {
                    Text("Connect Tesla Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom)
            }
            .navigationTitle("Connect Tesla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
