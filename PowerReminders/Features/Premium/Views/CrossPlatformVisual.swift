import SwiftUI

struct CrossPlatformVisual: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // iPhone
            DeviceIcon(
                systemName: "iphone",
                label: "iPhone"
            )
            .offset(x: isAnimating ? 0 : -10)
            .opacity(isAnimating ? 1 : 0)

            // Sync arrows
            SyncArrows()
                .opacity(isAnimating ? 1 : 0)

            // Android
            DeviceIcon(
                systemName: "smartphone",
                label: "Android"
            )
            .offset(x: isAnimating ? 0 : 10)
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Device Icon

private struct DeviceIcon: View {
    let systemName: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.Colors.premiumGradient)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sync Arrows

private struct SyncArrows: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.primary)
                .offset(x: isPulsing ? 3 : 0)

            Image(systemName: "arrow.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.primary)
                .offset(x: isPulsing ? -3 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Competitor Comparison

struct CompetitorComparison: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ComparisonRow(
                name: "Apple Reminders",
                limitation: "iOS only",
                hasFeature: false
            )

            ComparisonRow(
                name: "Google Tasks",
                limitation: "Google only",
                hasFeature: false
            )

            ComparisonRow(
                name: "Zalt",
                limitation: "Both platforms",
                hasFeature: true,
                isHighlighted: true
            )
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
    }
}

private struct ComparisonRow: View {
    let name: String
    let limitation: String
    let hasFeature: Bool
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(name)
                .font(isHighlighted ? Theme.Typography.headline : Theme.Typography.body)
                .foregroundStyle(isHighlighted ? Theme.Colors.primary : .primary)

            Spacer()

            Text(limitation)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)

            Image(systemName: hasFeature ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(hasFeature ? Theme.Colors.success : Theme.Colors.error.opacity(0.6))
        }
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.premiumGradient)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CrossPlatformVisual()
        CompetitorComparison()
        PremiumFeatureRow(
            icon: "icloud.fill",
            title: "Unlimited Devices",
            description: "Sync across all your devices"
        )
    }
    .padding()
}
