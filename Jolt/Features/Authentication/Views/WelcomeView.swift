import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // App icon and title
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)

                    Text("Jolt")
                        .font(Theme.Typography.largeTitle)
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

                // Sign in button
                VStack(spacing: Theme.Spacing.md) {
                    Button(action: signInWithGoogle) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(Theme.Typography.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    }
                    .disabled(authViewModel.isLoading)
                    .opacity(isAnimating ? 1.0 : 0.0)

                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.error)
                            .multilineTextAlignment(.center)
                    }

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1.0 : 0.0)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    private func signInWithGoogle() {
        Haptics.medium()
        Task {
            await authViewModel.signInWithGoogle()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Theme.Typography.headline)
                Text(description)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .liquidGlass()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
