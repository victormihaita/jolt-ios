import SwiftUI

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
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
                case .premiumValue:
                    OnboardingPremiumValueWrapperView(viewModel: viewModel)
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
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)

            // Page indicator overlayed at bottom
            if viewModel.currentStep != .premiumValue && viewModel.currentStep != .paywall && viewModel.currentStep != .completed {
                OnboardingPageIndicator(
                    totalPages: 4,
                    currentPage: min(viewModel.currentStep.rawValue, 3)
                )
                .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(.keyboard)
        .dismissKeyboardOnTap() // Allow dismissing keyboard by tapping
        .environmentObject(viewModel)
    }
}

// MARK: - Premium Value Wrapper for Onboarding

struct OnboardingPremiumValueWrapperView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        PremiumValueView(
            onDismiss: {
                viewModel.completeOnboarding()
            },
            onContinue: {
                viewModel.advanceToStep(.paywall)
            }
        )
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
