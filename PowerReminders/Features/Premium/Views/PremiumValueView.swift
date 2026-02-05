import SwiftUI

struct PremiumValueView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var showPaywall = false

    var onDismiss: (() -> Void)?
    var onContinue: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Theme.Colors.premiumStart.opacity(0.15),
                        Theme.Colors.premiumMid.opacity(0.1),
                        Theme.Colors.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        Spacer()
                            .frame(height: Theme.Spacing.lg)

                        // Cross-platform visual
                        CrossPlatformVisual()
                            .padding(.top, Theme.Spacing.md)

                        // Headline
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Your reminders, everywhere")
                                .font(Theme.Typography.title)
                                .multilineTextAlignment(.center)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 10)

                            Text("Create on iPhone, get reminded on Android. Complete on your tablet, see it done on your phone instantly.")
                                .font(Theme.Typography.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.md)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 10)
                        }

                        // Competitor comparison
                        CompetitorComparison()
                            .padding(.horizontal, Theme.Spacing.md)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 15)

                        // Premium features
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Premium includes:")
                                .font(Theme.Typography.headline)
                                .padding(.horizontal, Theme.Spacing.md)

                            VStack(spacing: Theme.Spacing.sm) {
                                PremiumFeatureRow(
                                    icon: "icloud.fill",
                                    title: "Unlimited device sync",
                                    description: "iPhone, Android, tablet — all connected"
                                )

                                PremiumFeatureRow(
                                    icon: "clock.arrow.circlepath",
                                    title: "Custom snooze",
                                    description: "22 minutes? 47 minutes? You decide."
                                )

                                PremiumFeatureRow(
                                    icon: "repeat",
                                    title: "Advanced recurring",
                                    description: "Every 3rd Tuesday, first Monday of each quarter"
                                )
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                        Spacer()
                            .frame(height: Theme.Spacing.xl)
                    }
                }

                // Bottom CTA
                VStack {
                    Spacer()

                    VStack(spacing: Theme.Spacing.md) {
                        Button {
                            Haptics.medium()
                            if let onContinue {
                                onContinue()
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Text("See Premium Options")
                                .font(Theme.Typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.Colors.premiumGradient)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                        }

                        Button {
                            Haptics.light()
                            if let onDismiss {
                                onDismiss()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text("Not now")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 48)
                    .background(
                        LinearGradient(
                            colors: [
                                Theme.Colors.background.opacity(0),
                                Theme.Colors.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(onDismiss: {
                    showPaywall = false
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                })
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    PremiumValueView()
}
