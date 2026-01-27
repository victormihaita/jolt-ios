import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient - Electric Cyan theme
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

                    Text("Power Reminders")
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
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.black)
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                            }
                            Text("Continue with Google")
                                .font(Theme.Typography.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(authViewModel.isLoading ? Theme.Colors.primary.opacity(0.7) : Theme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    }
                    .disabled(authViewModel.isLoading)
                    .opacity(isAnimating ? 1.0 : 0.0)

                    // Fixed height container for error message to prevent layout jumps
                    Group {
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(minHeight: 20)

                    VStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 0) {
                            Link("Terms of Service", destination: URL(string: "https://jolt-website-liart.vercel.app/terms")!)
                                .font(Theme.Typography.caption.bold())
                                .foregroundColor(Theme.Colors.primary)
                            Text(" and ")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                            Link("Privacy Policy", destination: URL(string: "https://jolt-website-liart.vercel.app/privacy")!)
                                .font(Theme.Typography.caption.bold())
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
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
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.primary.opacity(0.15))
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
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
