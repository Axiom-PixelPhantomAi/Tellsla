import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage: Int = 0
    @State private var appeared: Bool = false

    private let pages = TutorialData.onboardingPages

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page, isActive: currentPage == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.snappy, value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.snappy) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear { appeared = true }
    }
}

struct OnboardingPageView: View {
    let page: TutorialPage
    let isActive: Bool
    @State private var animateFeatures: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Spacer().frame(height: 40)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(accentColor)
                        .symbolEffect(.bounce, value: isActive)

                    Text(page.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)

                    Text(page.subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accentColor)

                    Text(page.description)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(4)
                }

                VStack(spacing: 16) {
                    ForEach(Array(page.features.enumerated()), id: \.element.id) { index, feature in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(accentColor)
                                .frame(width: 36, height: 36)
                                .background(accentColor.opacity(0.15))
                                .clipShape(.rect(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineSpacing(2)
                            }
                        }
                        .opacity(animateFeatures ? 1 : 0)
                        .offset(y: animateFeatures ? 0 : 16)
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: animateFeatures)
                    }
                }

                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateFeatures = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    animateFeatures = true
                }
            }
        }
        .onAppear {
            if isActive { animateFeatures = true }
        }
    }

    private var accentColor: Color {
        switch page.accentColorName {
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "cyan": return .cyan
        case "red": return .red
        default: return .blue
        }
    }
}
