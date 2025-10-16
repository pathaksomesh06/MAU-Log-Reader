import Foundation
import AppKit
import UniformTypeIdentifiers

class ExportManager {
    
    static func exportToCSV(entries: [LogEntry]) -> String {
        var csv = "Timestamp,App,Level,Message\n"
        
        for entry in entries {
            let message = entry.message.replacingOccurrences(of: "\"", with: "\"\"")
            let line = "\"\(entry.timestampString)\",\"\(entry.app)\",\"\(entry.level)\",\"\(message)\"\n"
            csv.append(line)
        }
        
        return csv
    }
    
    static func exportToJSON(entries: [LogEntry]) -> String {
        var jsonArray: [[String: Any]] = []
        
        for entry in entries {
            let dict: [String: Any] = [
                "timestamp": entry.timestampString,
                "app": entry.app,
                "level": entry.level,
                "message": entry.message,
                "type": entry.logType,
                "isError": entry.isError,
                "isWarning": entry.isWarning
            ]
            jsonArray.append(dict)
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "[]"
    }
    
    static func saveFile(content: String, fileName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = fileName.contains(".csv") ? [UTType.commaSeparatedText] : [UTType.json]
        panel.nameFieldStringValue = fileName
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
}
