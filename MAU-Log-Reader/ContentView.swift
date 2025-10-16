import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var monitor = FileMonitor()
    @State private var selectedLevel: LogLevel = .all
    @State private var selectedApp: MicrosoftApp = .all
    @State private var searchText = ""
    @State private var autoRefresh = true
    @State private var selectedEntry: LogEntry?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                monitor: monitor,
                selectedLevel: $selectedLevel,
                selectedApp: $selectedApp,
                autoRefresh: $autoRefresh
            )
            .navigationSplitViewColumnWidth(250)
        } content: {
            Group {
                if monitor.entries.isEmpty {
                    EmptyStateView(monitor: monitor)
                } else {
                    LogListView(
                        entries: selectedLevel == .all && selectedApp == .all ? monitor.entries : filteredEntries,
                        searchText: $searchText,
                        selectedEntry: $selectedEntry
                    )
                }
            }
            .navigationSplitViewColumnWidth(500)
        } detail: {
            if let selectedEntry = selectedEntry {
                LogDetailView(entry: selectedEntry)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select a log entry")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("MAU Log Reader")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Load Latest") {
                    monitor.loadLatestLog()
                }
                .keyboardShortcut("l", modifiers: [.command])
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Browse...") {
                    browseForLog()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu("Export") {
                    Button("Export as CSV") {
                        let csv = ExportManager.exportToCSV(entries: monitor.entries)
                        let fileName = "MAU-Logs-\(Date().formatted(date: .numeric, time: .standard)).csv"
                        ExportManager.saveFile(content: csv, fileName: fileName)
                    }
                    Button("Export as JSON") {
                        let json = ExportManager.exportToJSON(entries: monitor.entries)
                        let fileName = "MAU-Logs-\(Date().formatted(date: .numeric, time: .standard)).json"
                        ExportManager.saveFile(content: json, fileName: fileName)
                    }
                }
                .disabled(monitor.entries.isEmpty)
            }
            
            ToolbarItem(placement: .automatic) {
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
        .onAppear {
            monitor.loadLatestLog()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
    
    private var filteredEntries: [LogEntry] {
        monitor.entries.filter { entry in
            let levelMatch = selectedLevel == .all || 
                (selectedLevel == .error && entry.isError) ||
                (selectedLevel == .warning && entry.isWarning) ||
                (selectedLevel == .info && !entry.isError && !entry.isWarning)
            
            let appMatch = selectedApp == .all || entry.microsoftApp == selectedApp
            
            let searchMatch = searchText.isEmpty ||
                entry.message.localizedCaseInsensitiveContains(searchText) ||
                entry.app.localizedCaseInsensitiveContains(searchText)
            
            return levelMatch && appMatch && searchMatch
        }
    }
    
    func browseForLog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.plainText, UTType.log]
        panel.directoryURL = URL(fileURLWithPath: "/Library/Logs/Microsoft")
        
        if panel.runModal() == .OK, let url = panel.url {
            monitor.loadLog(from: url.path)
        }
    }
}

enum LogLevel: String, CaseIterable, Identifiable {
    case all = "All Logs"
    case error = "Errors"
    case warning = "Warnings"
    case info = "Info"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .error: return .red
        case .warning: return .orange
        case .info: return .green
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @ObservedObject var monitor: FileMonitor
    @Binding var selectedLevel: LogLevel
    @Binding var selectedApp: MicrosoftApp
    @Binding var autoRefresh: Bool
    
    var stats: (total: Int, errors: Int, warnings: Int) {
        (
            monitor.entries.count,
            monitor.entries.filter { $0.isError }.count,
            monitor.entries.filter { $0.isWarning }.count
        )
    }
    
    var body: some View {
        List {
            Section("Status") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(monitor.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(monitor.isMonitoring ? "Monitoring" : "Stopped")
                        .font(.subheadline)
                }
            }
            
            Section("Applications") {
                ForEach(MicrosoftApp.allCases) { app in
                    AppRowView(
                        app: app,
                        isSelected: selectedApp == app,
                        entryCount: getAppEntryCount(for: app),
                        errorCount: getAppErrorCount(for: app)
                    ) {
                        selectedApp = app
                    }
                }
            }
            
            Section("Metrics") {
                MetricRow(label: "Total", value: stats.total, color: .blue)
                MetricRow(label: "Errors", value: stats.errors, color: .red)
                MetricRow(label: "Warnings", value: stats.warnings, color: .orange)
            }
        }
        .listStyle(.sidebar)
    }
    
    private func getAppEntryCount(for app: MicrosoftApp) -> Int {
        if app == .all {
            return monitor.entries.count
        }
        return monitor.entries.filter { $0.microsoftApp == app }.count
    }
    
    private func getAppErrorCount(for app: MicrosoftApp) -> Int {
        if app == .all {
            return monitor.entries.filter { $0.isError }.count
        }
        return monitor.entries.filter { $0.microsoftApp == app && $0.isError }.count
    }
}

struct MetricRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct AppRowView: View {
    let app: MicrosoftApp
    let isSelected: Bool
    let entryCount: Int
    let errorCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: app.icon)
                    .foregroundColor(app.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.rawValue)
                        .font(.subheadline)
                    Text("\(entryCount) entries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if errorCount > 0 {
                    Text("\(errorCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? app.color.opacity(0.1) : Color.clear)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    @ObservedObject var monitor: FileMonitor
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Log Loaded")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = monitor.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else {
                Text("Click 'Load Latest' to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("/Library/Logs/Microsoft/")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject var monitor: FileMonitor
    
    var stats: (total: Int, errors: Int, warnings: Int, errorRate: Double) {
        let errors = monitor.entries.filter { $0.isError }.count
        let warnings = monitor.entries.filter { $0.isWarning }.count
        let rate = monitor.entries.count > 0 ? Double(errors) / Double(monitor.entries.count) * 100 : 0
        return (monitor.entries.count, errors, warnings, rate)
    }
    
    var topApps: [(app: String, count: Int)] {
        let grouped = Dictionary(grouping: monitor.entries, by: { $0.app })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 12) {
                    StatCard(title: "Total Entries", value: "\(stats.total)", icon: "doc.text.fill", color: .blue)
                    StatCard(title: "Errors", value: "\(stats.errors)", icon: "exclamationmark.triangle.fill", color: .red)
                    StatCard(title: "Warnings", value: "\(stats.warnings)", icon: "exclamationmark.circle.fill", color: .orange)
                    StatCard(title: "Error Rate", value: String(format: "%.1f%%", stats.errorRate), icon: "chart.line.uptrend.xyaxis", color: .purple)
                }
                
                // Top Apps
                if !topApps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Applications")
                            .font(.headline)
                        
                        ForEach(Array(topApps.enumerated()), id: \.offset) { index, app in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                
                                Text(app.app)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(app.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Log List
struct LogListView: View {
    let entries: [LogEntry]
    @Binding var searchText: String
    @Binding var selectedEntry: LogEntry?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            Divider()
            
            // List
            if entries.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No entries")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries, selection: $selectedEntry) { entry in
                    LogRow(entry: entry)
                        .tag(entry)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct LogRow: View {
    let entry: LogEntry
    
    var levelColor: Color {
        if entry.isError { return .red }
        if entry.isWarning { return .orange }
        return .blue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(levelColor)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.level.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelColor.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(entry.app)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(entry.timestampString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Text(entry.message)
                    .font(.subheadline)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Detail View
struct LogDetailView: View {
    let entry: LogEntry
    
    var levelColor: Color {
        if entry.isError { return .red }
        if entry.isWarning { return .orange }
        return .blue
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: entry.isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.title)
                        .foregroundStyle(levelColor)
                    
                    VStack(alignment: .leading) {
                        Text(entry.level.uppercased())
                            .font(.headline)
                            .foregroundStyle(levelColor)
                        Text(entry.app)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(entry.timestampString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Application Information")
                        .font(.headline)
                    
                    InfoRow(label: "Application", value: entry.app)
                    InfoRow(label: "Microsoft App", value: entry.microsoftApp.rawValue)
                    InfoRow(label: "Log Type", value: entry.logType)
                    InfoRow(label: "Level", value: entry.level)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Meaning
                VStack(alignment: .leading, spacing: 12) {
                    Text("What This Means")
                        .font(.headline)
                    Text(entry.humanReadableMessage)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Message
                VStack(alignment: .leading, spacing: 12) {
                    Text("Original Message")
                        .font(.headline)
                    Text(entry.message)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Raw
                VStack(alignment: .leading, spacing: 12) {
                    Text("Raw Log Data")
                        .font(.headline)
                    Text(entry.rawLine)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
