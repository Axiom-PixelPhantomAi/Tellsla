import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView {
                    appState.completeOnboarding()
                }
            } else if !appState.isAuthenticated {
                AuthView {
                    appState.isAuthenticated = true
                }
            } else {
                MainView(appState: appState)
            }
        }
        .animation(.smooth, value: appState.isAuthenticated)
        .animation(.smooth, value: appState.hasCompletedOnboarding)
    }
}
