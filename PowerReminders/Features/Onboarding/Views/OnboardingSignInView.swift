import SwiftUI
import AuthenticationServices

struct OnboardingSignInView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Theme.Colors.primary.opacity(0.15),
                    Theme.Colors.premiumStart.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Header
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentColor)

                    Text("Save your reminder &\nsync across devices")
                        .font(Theme.Typography.largeTitle)
                        .multilineTextAlignment(.center)

                    Text("Sign in to keep your data safe and access it on all your devices.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()

                // Sign in buttons
                VStack(spacing: Theme.Spacing.md) {
                    // Sign in with Apple
                    Button(action: signInWithApple) {
                        HStack(spacing: Theme.Spacing.sm) {
                            if authViewModel.authenticatingProvider == .apple {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "apple.logo")
                                    .font(.title2)
                            }
                            Text("Continue with Apple")
                                .font(Theme.Typography.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(authViewModel.isLoading ? Color.black.opacity(0.7) : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    }
                    .disabled(authViewModel.isLoading)

                    // Sign in with Google
                    Button(action: signInWithGoogle) {
                        HStack(spacing: Theme.Spacing.sm) {
                            if authViewModel.authenticatingProvider == .google {
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
                        .background(authViewModel.isLoading ? Color.accentColor.opacity(0.7) : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    }
                    .disabled(authViewModel.isLoading)

                    // Error message
                    Group {
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(minHeight: 20)

                    // Terms
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
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, 48)
            }
        }
        .alert("Account Pending Deletion", isPresented: $authViewModel.showRestoreAccountPrompt) {
            Button("Restore Account") {
                Task {
                    await authViewModel.restoreAccount()
                }
            }
            Button("Cancel", role: .cancel) {
                Task {
                    await authViewModel.declineRestore()
                }
            }
        } message: {
            Text("Your account was scheduled for deletion. Would you like to restore your account and all your data?")
        }
    }

    private func signInWithGoogle() {
        Haptics.medium()
        Task {
            await authViewModel.signInWithGoogle()
        }
    }

    private func signInWithApple() {
        Haptics.medium()
        Task {
            await authViewModel.signInWithApple()
        }
    }
}
