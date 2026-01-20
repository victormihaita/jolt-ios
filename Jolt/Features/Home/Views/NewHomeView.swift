import SwiftUI
import JoltModels
import JoltSync

struct NewHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var showNaturalLanguageInput = false
    @State private var showSettingsSheet = false
    @State private var showCreateListSheet = false
    @State private var selectedFilter: SmartFilterType?
    @State private var selectedList: ReminderList?
    @State private var selectedReminder: JoltModels.Reminder?
    @State private var searchText = ""

    @Namespace private var namespace

    /// Default list ID for creating reminders from home
    private var defaultListId: UUID {
        syncEngine.reminderLists.first(where: { $0.isDefault })?.id
            ?? syncEngine.reminderLists.first?.id
            ?? UUID()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Quick Capture Bar
                    QuickCaptureBar(text: $viewModel.quickCaptureText) { parsed in
                        Task {
                            if let reminder = await viewModel.createReminderFromQuickCapture() {
                                selectedReminder = reminder
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)

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
                        onNewListTap: {
                            showCreateListSheet = true
                        },
                        onDeleteList: { list in
                            Task {
                                await viewModel.deleteList(list)
                            }
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search all reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Haptics.light()
                        showSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                Button(action: {
                    Haptics.medium()
                    showNaturalLanguageInput = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .matchedTransitionSource(id: "createReminder", in: namespace) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.trailing, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .fullScreenCover(isPresented: $showNaturalLanguageInput) {
                NaturalLanguageInputView(listId: defaultListId) { reminder in
                    selectedReminder = reminder
                }
                .navigationTransition(.zoom(sourceID: "createReminder", in: namespace))
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                ReminderDetailView(reminder: reminder)
            }
            .fullScreenCover(isPresented: $showSettingsSheet) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
            }
            .fullScreenCover(isPresented: $showCreateListSheet) {
                CreateListView { name, colorHex, iconName in
                    Task {
                        await viewModel.createList(name: name, colorHex: colorHex, iconName: iconName)
                    }
                }
                .navigationTransition(.zoom(sourceID: "newList", in: namespace))
            }
            .fullScreenCover(item: $selectedFilter) { filter in
                FilteredRemindersView(filterType: filter)
                    .navigationTransition(.zoom(sourceID: "filter-\(filter.title)", in: namespace))
            }
            .fullScreenCover(item: $selectedList) { list in
                ListDetailView(list: list)
                    .navigationTransition(.zoom(sourceID: "list-\(list.id.uuidString)", in: namespace))
            }
            .refreshable {
                syncEngine.refetch()
            }
            .onAppear {
                syncEngine.connect()
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
}
