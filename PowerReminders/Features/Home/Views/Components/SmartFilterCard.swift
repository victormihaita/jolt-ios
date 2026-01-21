import SwiftUI

struct SmartFilterCard: View {
    let filterType: SmartFilterType
    let count: Int
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Top row: Icon on left, count on right
                HStack {
                    Image(systemName: filterType.icon)
                        .font(.title)
                        .foregroundStyle(filterType.color)

                    Spacer()

                    Text("\(count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Title at bottom
                Text(filterType.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        filterType.color.opacity(0.15),
                        filterType.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .modifier(MatchedTransitionSourceModifier(id: "filter-\(filterType.title)", namespace: namespace))
    }
}

// MARK: - Smart Filter Type

enum SmartFilterType: CaseIterable {
    case today
    case all
    case scheduled
    case completed

    var title: String {
        switch self {
        case .today: return "Today"
        case .all: return "All"
        case .scheduled: return "Scheduled"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .today: return "calendar"
        case .all: return "tray.fill"
        case .scheduled: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .today: return .blue
        case .all: return .gray
        case .scheduled: return .orange
        case .completed: return .green
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    HStack {
        SmartFilterCard(filterType: .today, count: 5, namespace: namespace) {}
        SmartFilterCard(filterType: .all, count: 23, namespace: namespace) {}
    }
    .padding()
}
