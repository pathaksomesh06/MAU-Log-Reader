import SwiftUI

struct AnalyticsView: View {
    let entries: [LogEntry]
    @Environment(\.dismiss) var dismiss
    
    private var patterns: [ErrorPattern] {
        ErrorAnalyzer.detectPatterns(entries: entries)
    }
    
    private var appErrors: [(app: String, errorCount: Int)] {
        ErrorAnalyzer.appErrorSummary(entries: entries)
    }
    
    private var stats: (total: Int, errors: Int, warnings: Int, debug: Int, info: Int) {
        let errors = entries.filter { $0.isError }.count
        let warnings = entries.filter { $0.isWarning }.count
        let debug = entries.filter { $0.level.lowercased() == "debug" }.count
        let info = entries.filter { $0.level.lowercased() == "info" }.count
        return (entries.count, errors, warnings, debug, info)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analytics Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Stats Grid - 3x2 layout
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            AnalyticsStatCard(label: "Total", value: "\(stats.total)", icon: "list.bullet", color: .blue)
                            AnalyticsStatCard(label: "Errors", value: "\(stats.errors)", icon: "exclamationmark.triangle.fill", color: .red)
                            AnalyticsStatCard(label: "Warnings", value: "\(stats.warnings)", icon: "exclamationmark.circle.fill", color: .orange)
                            AnalyticsStatCard(label: "Debug", value: "\(stats.debug)", icon: "ant.fill", color: .gray)
                            AnalyticsStatCard(label: "Info", value: "\(stats.info)", icon: "info.circle.fill", color: .green)
                            AnalyticsStatCard(
                                label: "Error Rate",
                                value: String(format: "%.1f%%", stats.total > 0 ? Double(stats.errors) / Double(stats.total) * 100 : 0),
                                icon: "chart.line.uptrend.xyaxis",
                                color: .purple
                            )
                        }
                    }
                    .padding(20)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Error Patterns Section
                    if !patterns.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.orange)
                                Text("Error Patterns")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(patterns) { pattern in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(pattern.pattern)
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.medium)
                                            
                                            HStack(spacing: 8) {
                                                Text("Severity:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Text(pattern.severity)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(pattern.severity == "High" ? .red : .orange)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        (pattern.severity == "High" ? Color.red : Color.orange).opacity(0.15)
                                                    )
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(spacing: 2) {
                                            Text("\(pattern.count)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(pattern.severity == "High" ? .red : .orange)
                                            Text("occurrences")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    
                    // Top Apps Section
                    if !appErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("Top Apps")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(appErrors.prefix(5), id: \.app) { item in
                                    HStack(spacing: 12) {
                                        Text(item.app)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .frame(width: 150, alignment: .leading)
                                        
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red.opacity(0.1))
                                                .frame(height: 24)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red.opacity(0.6))
                                                .frame(
                                                    width: max(40, CGFloat(item.errorCount) / CGFloat(appErrors.first?.errorCount ?? 1) * 200),
                                                    height: 24
                                                )
                                        }
                                        
                                        Text("\(item.errorCount)")
                                            .font(.callout)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                            .frame(minWidth: 40, alignment: .trailing)
                                    }
                                    .padding(12)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
}

struct AnalyticsStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AnalyticsView(entries: [])
}
