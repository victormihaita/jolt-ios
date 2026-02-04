import SwiftUI
import PRModels
import PRSync

struct NewHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var showCreateReminder = false
    @State private var showSettingsSheet = false
    @State private var selectedFilter: SmartFilterType?
    @State private var selectedList: ReminderList?
    @State private var selectedReminder: PRModels.Reminder?
    @State private var searchText = ""
    @State private var isCreatingList = false
    @State private var isEditingList = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var namespace

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    /// Default list ID for creating reminders from home
    private var defaultListId: UUID {
        syncEngine.reminderLists.first(where: { $0.isDefault })?.id
            ?? syncEngine.reminderLists.first?.id
            ?? UUID()
    }

    /// Search results filtered from all reminders
    private var searchResults: [PRModels.Reminder] {
        guard !searchText.isEmpty else { return [] }
        return syncEngine.reminders
            .filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                (reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            .sorted { r1, r2 in
                // Reminders without dates go to the end
                switch (r1.dueAt, r2.dueAt) {
                case (nil, nil): return r1.createdAt > r2.createdAt
                case (nil, _): return false
                case (_, nil): return true
                case (let d1?, let d2?): return d1 < d2
                }
            }
    }

    /// Check if we're currently searching
    private var isSearching: Bool {
        !searchText.isEmpty
    }

    /// User's first name for greeting
    private var userFirstName: String {
        guard let displayName = authViewModel.currentUser?.displayName else {
            return "there"
        }
        return displayName.components(separatedBy: " ").first ?? displayName
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    // Search Results View
                    searchResultsView
                } else {
                    // Default Home Content
                    homeContentView
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Hi, \(userFirstName)")
            .searchable(text: $searchText, prompt: "Search all reminders")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SyncStatusView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Haptics.light()
                        showSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                    .modifier(MatchedTransitionSourceModifier(id: "settings", namespace: namespace))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button - hidden when creating or editing a list
                if !isCreatingList && !isEditingList {
                    Button(action: {
                        Haptics.medium()
                        showCreateReminder = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .contentShape(Circle())
                    .buttonStyle(.plain)
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .modifier(AdaptivePresentation(isPresented: $showCreateReminder, isRegularWidth: isRegularWidth) {
                CreateReminderView(preselectedListId: defaultListId)
                    .navigationTransition(.zoom(sourceID: "createReminder", in: namespace))
            })
            .modifier(AdaptiveItemPresentation(item: $selectedReminder, isRegularWidth: isRegularWidth) { reminder in
                CreateReminderView(editingReminder: reminder)
            })
            .modifier(AdaptivePresentation(isPresented: $showSettingsSheet, isRegularWidth: isRegularWidth) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
            })
            .modifier(AdaptiveItemPresentation(item: $selectedFilter, isRegularWidth: isRegularWidth) { filter in
                FilteredRemindersView(filterType: filter)
                    .navigationTransition(.zoom(sourceID: "filter-\(filter.title)", in: namespace))
            })
            .modifier(AdaptiveItemPresentation(item: $selectedList, isRegularWidth: isRegularWidth) { list in
                ListDetailView(list: list)
                    .navigationTransition(.zoom(sourceID: "list-\(list.id.uuidString)", in: namespace))
            })
            .onAppear {
                syncEngine.connect()
            }
        }
    }

    // MARK: - Home Content View

    private var homeContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Smart Filters Grid
                    SmartFiltersGrid(
                        todayCount: viewModel.todayCount,
                        allCount: viewModel.allCount,
                        scheduledCount: viewModel.scheduledCount,
                        completedCount: viewModel.completedCount,
                        namespace: namespace
                    ) { filter in
                        selectedFilter = filter
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Lists Section
                    ListsSection(
                        lists: syncEngine.reminderLists,
                        reminderCountForList: { list in
                            list.reminderCount
                        },
                        namespace: namespace,
                        onListTap: { list in
                            selectedList = list
                        },
                        onCreateList: { name, colorHex, iconName in
                            Task {
                                await viewModel.createList(name: name, colorHex: colorHex, iconName: iconName)
                            }
                        },
                        onDeleteList: { list in
                            Task {
                                await viewModel.deleteList(list)
                            }
                        },
                        isCreatingList: $isCreatingList,
                        isEditingList: $isEditingList
                    )
                    .padding(.horizontal, Theme.Spacing.md)

                    // Scroll anchor
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: isCreatingList) { _, isCreating in
                if isCreating {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.snappy) {
                            proxy.scrollTo("bottom", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        Group {
            if searchResults.isEmpty {
                // Empty search results
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    Text("No results for \"\(searchText)\"")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.secondary)
                    Text("Try searching for a different term")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Search results list
                List {
                    ForEach(searchResults) { reminder in
                        SearchResultRow(reminder: reminder, listName: listName(for: reminder))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedReminder = reminder
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Helper Methods

    private func listName(for reminder: PRModels.Reminder) -> String {
        syncEngine.reminderLists.first(where: { $0.id == reminder.listId })?.name ?? "Unknown"
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let reminder: PRModels.Reminder
    let listName: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(reminder.title)
                    .font(Theme.Typography.headline)
                    .lineLimit(2)

                HStack(spacing: Theme.Spacing.sm) {
                    // List name
                    Label(listName, systemImage: "list.bullet")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)

                    // Due date (only show if set)
                    if reminder.dueAt != nil {
                        Label(formattedDueDate, systemImage: "clock")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(reminder.isOverdue ? Theme.Colors.error : .secondary)
                    } else {
                        Label("No date", systemImage: "calendar.badge.minus")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Recurrence indicator
                    if reminder.isRecurring {
                        Image(systemName: "repeat")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var priorityColor: Color {
        switch reminder.priority {
        case .high: return Theme.Colors.priorityHigh
        case .normal: return Theme.Colors.priorityNormal
        case .low: return Theme.Colors.priorityLow
        case .none: return Theme.Colors.priorityNone
        }
    }

    private var formattedDueDate: String {
        guard reminder.dueAt != nil else { return "No date" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: reminder.effectiveDueDate, relativeTo: Date())
    }
}

// MARK: - Adaptive Presentation Modifiers (iPad sheet / iPhone fullScreenCover)

/// Presents content as a sheet on iPad (regular width) or fullScreenCover on iPhone.
struct AdaptivePresentation<PresentedContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let isRegularWidth: Bool
    @ViewBuilder let presentedContent: () -> PresentedContent

    func body(content: Content) -> some View {
        if isRegularWidth {
            content.sheet(isPresented: $isPresented) {
                presentedContent()
            }
        } else {
            content.fullScreenCover(isPresented: $isPresented) {
                presentedContent()
            }
        }
    }
}

/// Item-based adaptive presentation: sheet on iPad, fullScreenCover on iPhone.
struct AdaptiveItemPresentation<Item: Identifiable, PresentedContent: View>: ViewModifier {
    @Binding var item: Item?
    let isRegularWidth: Bool
    @ViewBuilder let presentedContent: (Item) -> PresentedContent

    func body(content: Content) -> some View {
        if isRegularWidth {
            content.sheet(item: $item) { item in
                presentedContent(item)
            }
        } else {
            content.fullScreenCover(item: $item) { item in
                presentedContent(item)
            }
        }
    }
}

// MARK: - Make SmartFilterType Identifiable for fullScreenCover

extension SmartFilterType: Identifiable {
    var id: String { title }
}

#Preview {
    NewHomeView()
        .environmentObject(AuthViewModel())
}
