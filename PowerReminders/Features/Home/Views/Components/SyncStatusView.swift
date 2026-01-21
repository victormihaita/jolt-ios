import SwiftUI
import PRSync

/// Displays the current sync status as a compact pill/badge
struct SyncStatusView: View {
    @ObservedObject private var syncEngine = SyncEngine.shared

    /// Whether to show the status even when synced (default: hide when synced)
    var showWhenSynced: Bool = false

    /// Compact mode shows only icon, expanded shows icon + text
    var compact: Bool = false

    var body: some View {
        // Hide when synced unless explicitly requested
        if shouldShow {
            HStack(spacing: compact ? 0 : 6) {
                statusIcon
                if !compact {
                    statusText
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 6 : 6)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: syncEngine.syncStatus)
        }
    }

    private var shouldShow: Bool {
        if showWhenSynced { return true }
        switch syncEngine.syncStatus {
        case .synced:
            return false
        default:
            return true
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch syncEngine.syncStatus {
        case .synced:
            Image(systemName: "checkmark.circle.fill")
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
                .tint(statusColor)
        case .offline:
            Image(systemName: "wifi.slash")
        case .pendingChanges:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
        }
    }

    private var statusText: Text {
        switch syncEngine.syncStatus {
        case .synced:
            return Text("Synced")
        case .syncing:
            return Text("Syncing...")
        case .offline:
            return Text("Offline")
        case .pendingChanges(let count):
            return Text("\(count) pending")
        case .error(let message):
            // Truncate long error messages
            let truncated = message.prefix(20)
            return Text(String(truncated) + (message.count > 20 ? "..." : ""))
        }
    }

    private var statusColor: Color {
        switch syncEngine.syncStatus {
        case .synced:
            return .green
        case .syncing:
            return .blue
        case .offline:
            return .orange
        case .pendingChanges:
            return .yellow
        case .error:
            return .red
        }
    }
}

/// Toolbar content for displaying sync status
struct SyncStatusToolbarContent: ToolbarContent {
    var compact: Bool = true

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SyncStatusView(compact: compact)
        }
    }
}

// MARK: - Preview

#Preview("Sync Status Views") {
    VStack(spacing: 20) {
        SyncStatusView(showWhenSynced: true)
        SyncStatusView(showWhenSynced: true, compact: true)
    }
    .padding()
}
