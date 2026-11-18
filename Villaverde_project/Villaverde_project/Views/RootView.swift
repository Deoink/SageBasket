import SwiftUI

/// Controls which top-level screen is shown:
/// Splash → Welcome (first launch only) → Onboarding (first launch only) → My Lists.
struct RootView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if userName.isEmpty {
                WelcomeView { name in
                    userName = name
                }
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                MyListsView()
            }
        }
        .onAppear {
            // Show the splash for a beat, then move on.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    RootView()
}
