import SwiftUI

struct OnboardingPersonalizationView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let categories = [
        ("briefcase.fill", "Work"),
        ("house.fill", "Personal"),
        ("heart.fill", "Health"),
        ("cart.fill", "Shopping"),
        ("book.fill", "Education"),
        ("banknote.fill", "Finance")
    ]

    private let frequencies = ["Daily", "A few times a week", "Occasionally"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Tell us about you")
                            .font(Theme.Typography.largeTitle)

                        Text("This helps us personalize your experience")
                            .font(Theme.Typography.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    // Question 1: Categories
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("What do you use reminders for?")
                            .font(Theme.Typography.headline)

                        FlowLayout(spacing: Theme.Spacing.sm) {
                            ForEach(categories, id: \.1) { icon, name in
                                CategoryChip(
                                    icon: icon,
                                    name: name,
                                    isSelected: viewModel.selectedCategories.contains(name)
                                ) {
                                    Haptics.selection()
                                    if viewModel.selectedCategories.contains(name) {
                                        viewModel.selectedCategories.remove(name)
                                    } else {
                                        viewModel.selectedCategories.insert(name)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Question 2: Frequency
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("How often do you create reminders?")
                            .font(Theme.Typography.headline)

                        VStack(spacing: Theme.Spacing.sm) {
                            ForEach(frequencies, id: \.self) { frequency in
                                FrequencyCard(
                                    title: frequency,
                                    isSelected: viewModel.reminderFrequency == frequency
                                ) {
                                    Haptics.selection()
                                    viewModel.reminderFrequency = frequency
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }

            // Bottom buttons
            VStack(spacing: Theme.Spacing.md) {
                Button {
                    Haptics.medium()
                    viewModel.advanceToStep(.createReminder)
                } label: {
                    Text("Continue")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(!viewModel.selectedCategories.isEmpty ? Color.accentColor : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                }
                .disabled(viewModel.selectedCategories.isEmpty)

                Button {
                    viewModel.advanceToStep(.createReminder)
                } label: {
                    Text("Skip")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(Theme.Typography.subheadline)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Theme.Colors.secondaryBackground)
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequency Card

private struct FrequencyCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.body)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
