import SwiftUI

struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Theme.Colors.primary.opacity(0.3),
                    Theme.Colors.premiumStart.opacity(0.2),
                    Theme.Colors.premiumMid.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // App icon and title
                VStack(spacing: Theme.Spacing.md) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)

                    Text("Never forget what matters.")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(.secondary)
                        .opacity(isAnimating ? 1.0 : 0.0)
                }

                Spacer()

                // Features list
                VStack(spacing: Theme.Spacing.md) {
                    FeatureRow(
                        icon: "clock.arrow.circlepath",
                        title: "Custom Snooze",
                        description: "Snooze for exactly 22 minutes"
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)

                    FeatureRow(
                        icon: "repeat",
                        title: "Smart Recurrence",
                        description: "Powerful recurring reminders"
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)

                    FeatureRow(
                        icon: "icloud.fill",
                        title: "Cross-Device Sync",
                        description: "Dismiss once, gone everywhere"
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()

                // Get Started button
                Button {
                    Haptics.medium()
                    viewModel.advanceToStep(.personalization)
                } label: {
                    Text("Get Started")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, 48)
                .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}
