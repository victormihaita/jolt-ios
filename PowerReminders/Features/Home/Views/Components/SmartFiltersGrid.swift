import SwiftUI

struct SmartFiltersGrid: View {
    let todayCount: Int
    let allCount: Int
    let scheduledCount: Int
    let completedCount: Int
    let namespace: Namespace.ID

    let onFilterTap: (SmartFilterType) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            SmartFilterCard(filterType: .today, count: todayCount, namespace: namespace) {
                onFilterTap(.today)
            }

            SmartFilterCard(filterType: .all, count: allCount, namespace: namespace) {
                onFilterTap(.all)
            }

            SmartFilterCard(filterType: .scheduled, count: scheduledCount, namespace: namespace) {
                onFilterTap(.scheduled)
            }

            SmartFilterCard(filterType: .completed, count: completedCount, namespace: namespace) {
                onFilterTap(.completed)
            }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    SmartFiltersGrid(
        todayCount: 5,
        allCount: 23,
        scheduledCount: 12,
        completedCount: 45,
        namespace: namespace
    ) { filter in
        print("Tapped \(filter.title)")
    }
    .padding()
}
