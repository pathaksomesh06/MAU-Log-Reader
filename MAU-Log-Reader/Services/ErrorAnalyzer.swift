import Foundation

struct ErrorPattern: Identifiable {
    let id = UUID()
    let pattern: String
    let count: Int
    let severity: String
}

class ErrorAnalyzer {
    
    static func detectPatterns(entries: [LogEntry]) -> [ErrorPattern] {
        let errorEntries = entries.filter { $0.isError || $0.isWarning }
        var patterns: [String: Int] = [:]
        
        for entry in errorEntries {
            let msg = entry.message.lowercased()
            
            if msg.contains("failed") {
                patterns["Failed Operation", default: 0] += 1
            }
            if msg.contains("error") || msg.contains("error code") {
                patterns["Error Code", default: 0] += 1
            }
            if msg.contains("download") && (msg.contains("failed") || msg.contains("error")) {
                patterns["Download Failure", default: 0] += 1
            }
            if msg.contains("cache") {
                patterns["Cache Issue", default: 0] += 1
            }
            if msg.contains("network") || msg.contains("url") {
                patterns["Network/URL Issue", default: 0] += 1
            }
            if msg.contains("permission") {
                patterns["Permission Issue", default: 0] += 1
            }
        }
        
        return patterns.map { key, value in
            ErrorPattern(pattern: key, count: value, severity: value > 5 ? "High" : "Medium")
        }
        .sorted { $0.count > $1.count }
    }
    
    static func appErrorSummary(entries: [LogEntry]) -> [(app: String, errorCount: Int)] {
        let errorsByApp = Dictionary(grouping: entries.filter { $0.isError }, by: { $0.app })
        
        return errorsByApp.map { (app: $0.key, errorCount: $0.value.count) }
            .sorted { $0.errorCount > $1.errorCount }
    }
    
    static func timelineStats(entries: [LogEntry]) -> [(hour: String, count: Int)] {
        let calendar = Calendar.current
        var hourCounts: [String: Int] = [:]
        
        for entry in entries {
            let components = calendar.dateComponents([.hour], from: entry.timestamp)
            let hour = String(format: "%02d:00", components.hour ?? 0)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts.map { (hour: $0.key, count: $0.value) }
            .sorted { $0.hour < $1.hour }
    }
}
