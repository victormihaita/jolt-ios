import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    OnboardingWelcomeView(viewModel: viewModel)
                case .personalization:
                    OnboardingPersonalizationView(viewModel: viewModel)
                case .createReminder:
                    OnboardingCreateReminderView(viewModel: viewModel)
                case .notifications:
                    OnboardingNotificationView(viewModel: viewModel)
                case .signIn:
                    OnboardingSignInView(viewModel: viewModel)
                case .paywall:
                    OnboardingPaywallWrapperView(viewModel: viewModel)
                case .completed:
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(viewModel.currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.smooth(duration: 0.35), value: viewModel.currentStep)

            // Page indicator overlayed at bottom
            if viewModel.currentStep != .paywall && viewModel.currentStep != .completed {
                OnboardingPageIndicator(
                    totalPages: 6,
                    currentPage: viewModel.currentStep.rawValue
                )
                .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(viewModel)
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && viewModel.currentStep == .signIn {
                Task {
                    await viewModel.syncPendingReminderToBackend()
                    viewModel.advanceToStep(.paywall)
                }
            }
        }
    }
}

// MARK: - Paywall Wrapper for Onboarding

struct OnboardingPaywallWrapperView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PaywallView(onDismiss: {
                viewModel.completeOnboarding()
            })

            Button {
                viewModel.completeOnboarding()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Page Indicator

struct OnboardingPageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage ? 10 : 8,
                           height: index == currentPage ? 10 : 8)
                    .animation(.snappy, value: currentPage)
            }
        }
    }
}
