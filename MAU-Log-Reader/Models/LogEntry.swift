import Foundation
import SwiftUI

struct LogEntry: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let timestampString: String
    let app: String
    let level: String
    let message: String
    let humanReadableMessage: String
    let rawLine: String
    let logType: String
    
    var isError: Bool {
        level.lowercased().contains("e") || level.lowercased() == "error"
    }
    
    var isWarning: Bool {
        level.lowercased().contains("warning")
    }
    
    // Extract the specific Microsoft application from the log entry
    var microsoftApp: MicrosoftApp {
        return MicrosoftApp.fromLogEntry(self)
    }
}

// Enum to represent different Microsoft applications
enum MicrosoftApp: String, CaseIterable, Identifiable {
    case all = "All Apps"
    case teams = "Teams"
    case outlook = "Outlook"
    case onedrive = "OneDrive"
    case companyPortal = "Company Portal"
    case word = "Word"
    case excel = "Excel"
    case powerpoint = "PowerPoint"
    case onenote = "OneNote"
    case copilot = "Microsoft Copilot"
    case defender = "Microsoft Defender"
    case quickAssist = "Quick Assist"
    case remoteHelp = "Remote Help"
    case skype = "Skype for Business"
    case windowsApp = "Windows App"
    case mau = "MAU"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .teams: return "message.circle.fill"
        case .outlook: return "envelope.circle.fill"
        case .onedrive: return "icloud.circle.fill"
        case .companyPortal: return "building.2.circle.fill"
        case .word: return "doc.circle.fill"
        case .excel: return "tablecells.circle.fill"
        case .powerpoint: return "presentation.circle.fill"
        case .onenote: return "note.text"
        case .copilot: return "sparkles"
        case .defender: return "shield.fill"
        case .quickAssist: return "questionmark.circle.fill"
        case .remoteHelp: return "person.crop.circle.fill"
        case .skype: return "video.circle.fill"
        case .windowsApp: return "app.badge"
        case .mau: return "arrow.down.circle.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .teams: return .purple
        case .outlook: return .blue
        case .onedrive: return .orange
        case .companyPortal: return .green
        case .word: return .blue
        case .excel: return .green
        case .powerpoint: return .orange
        case .onenote: return .purple
        case .copilot: return .cyan
        case .defender: return .red
        case .quickAssist: return .blue
        case .remoteHelp: return .green
        case .skype: return .blue
        case .windowsApp: return .blue
        case .mau: return .gray
        case .other: return .gray
        }
    }
    
    // Map AppIDs to Microsoft applications using official Microsoft Application Identifiers
    static func fromLogEntry(_ entry: LogEntry) -> MicrosoftApp {
        let message = entry.message.lowercased()
        let app = entry.app.lowercased()
        
        // Check for Teams (both versions)
        if message.contains("teams21") || message.contains("teams10") || 
           app.contains("teams21") || app.contains("teams10") {
            return .teams
        }
        
        // Check for Outlook
        if message.contains("opim2019") || app.contains("opim2019") {
            return .outlook
        }
        
        // Check for OneDrive
        if message.contains("ondr18") || app.contains("ondr18") {
            return .onedrive
        }
        
        // Check for Company Portal
        if message.contains("imcp01") || app.contains("imcp01") {
            return .companyPortal
        }
        
        // Check for Word
        if message.contains("mswd2019") || app.contains("mswd2019") {
            return .word
        }
        
        // Check for Excel
        if message.contains("xcel2019") || app.contains("xcel2019") {
            return .excel
        }
        
        // Check for PowerPoint
        if message.contains("ppt32019") || app.contains("ppt32019") {
            return .powerpoint
        }
        
        // Check for OneNote
        if message.contains("onmc2019") || app.contains("onmc2019") {
            return .onenote
        }
        
        // Check for Microsoft Copilot
        if message.contains("mscp10") || app.contains("mscp10") {
            return .copilot
        }
        
        // Check for Microsoft Defender (multiple variants)
        if message.contains("wdavconsumer") || message.contains("wdav00") || message.contains("wdavshim") ||
           app.contains("wdavconsumer") || app.contains("wdav00") || app.contains("wdavshim") {
            return .defender
        }
        
        // Check for Quick Assist
        if message.contains("msqa01") || app.contains("msqa01") {
            return .quickAssist
        }
        
        // Check for Remote Help
        if message.contains("msrh01") || app.contains("msrh01") {
            return .remoteHelp
        }
        
        // Check for Skype for Business
        if message.contains("msfb16") || app.contains("msfb16") {
            return .skype
        }
        
        // Check for Windows App
        if message.contains("msrd10") || app.contains("msrd10") {
            return .windowsApp
        }
        
        // Check for MAU
        if message.contains("msau04") || app.contains("msau04") {
            return .mau
        }
        
        return .other
    }

    static func fromAppIdString(_ appIdString: String) -> MicrosoftApp {
        let lowerAppId = appIdString.lowercased()
        
        if lowerAppId.contains("teams21") || lowerAppId.contains("teams10") { return .teams }
        if lowerAppId.contains("opim2019") { return .outlook }
        if lowerAppId.contains("ondr18") { return .onedrive }
        if lowerAppId.contains("imcp01") { return .companyPortal }
        if lowerAppId.contains("mswd2019") { return .word }
        if lowerAppId.contains("xcel2019") { return .excel }
        if lowerAppId.contains("ppt32019") { return .powerpoint }
        if lowerAppId.contains("onmc2019") { return .onenote }
        if lowerAppId.contains("mscp10") { return .copilot }
        if lowerAppId.contains("wdavconsumer") || lowerAppId.contains("wdav00") || lowerAppId.contains("wdavshim") { return .defender }
        if lowerAppId.contains("msqa01") { return .quickAssist }
        if lowerAppId.contains("msrh01") { return .remoteHelp }
        if lowerAppId.contains("msfb16") { return .skype }
        if lowerAppId.contains("msrd10") { return .windowsApp }
        if lowerAppId.contains("msau04") { return .mau }
        
        return .other
    }
}

struct PayloadData: Codable {
    let Payload: String?
}

struct ErrorData: Codable {
    let Error: String?
    let Operation: String?
    let AppID: String?
    let UpdateID: String?
    let ErrorCode: String?
}

class LogParser {
    // Helper to extract key=value pairs for more detailed explanations
    private static func extractValue(from message: String, forKey key: String) -> String? {
        // This regex looks for a key followed by a colon, optional whitespace, and then captures the value.
        // It handles values that are quoted or unquoted, stopping at a comma, whitespace, or closing brace.
        let pattern = #""?\#(key)"?\s*[:=]\s*"([^",}]+)""#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: message.utf16.count)
            if let match = regex.firstMatch(in: message, options: [], range: range) {
                if let valueRange = Range(match.range(at: 1), in: message) {
                    return String(message[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    // Create simple, clear explanation for any log message
    private static func createSimpleExplanation(for message: String, app: String, level: String) -> String {
        let lowerMessage = message.lowercased()

        // Update BaseVersions Found
        if lowerMessage.contains("update baseversions found") {
            let pattern = #"AppId:\s*(\w+)\s*=\s*\{\s*\(\(\s*"([^"]+)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: message.utf16.count)
                if let match = regex.firstMatch(in: message, options: [], range: range) {
                    if let appRange = Range(match.range(at: 1), in: message),
                       let versionRange = Range(match.range(at: 2), in: message) {
                        let appId = String(message[appRange])
                        let version = String(message[versionRange])
                        let appEnum = MicrosoftApp.fromAppIdString(appId)
                        let appName = appEnum == .other ? appId : appEnum.rawValue
                        return "MAU has identified that \(appName) (version \(version)) is installed. This is a step in checking for updates."
                    }
                }
            }
            return "MAU is checking the version of an installed application to see if an update is available."
        }

        // Application Forced Update Schedule
        if lowerMessage.contains("application forced update schedule") {
            let pattern = #"\{\s*(\w+)\s*="#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: message.utf16.count)
                if let match = regex.firstMatch(in: message, options: [], range: range) {
                    if let appRange = Range(match.range(at: 1), in: message) {
                        let appId = String(message[appRange])
                        let appEnum = MicrosoftApp.fromAppIdString(appId)
                        let appName = appEnum == .other ? appId : appEnum.rawValue
                         if let date = extractValue(from: message, forKey: "ForcedUpdateDate") {
                            return "A mandatory update for \(appName) has been scheduled by MAU for \(date)."
                        }
                        return "A mandatory update for \(appName) has been scheduled by MAU."
                    }
                }
            }
            return "MAU is planning to force updates for an Office application to ensure all users have the latest security patches and features."
        }
        
        // CloningTask
        if lowerMessage.contains("cloningtask") {
            if let appId = extractValue(from: message, forKey: "AppID") {
                let appEnum = MicrosoftApp.fromAppIdString(appId)
                let appName = appEnum == .other ? appId : appEnum.rawValue
                if lowerMessage.contains("begin") {
                    return "Starting to prepare update files for \(appName)."
                }
                 if lowerMessage.contains("appnamechanged") {
                    if message.contains("Success: YES") {
                        return "Successfully prepared update files for \(appName)."
                    } else {
                        return "Failed to prepare update files for \(appName)."
                    }
                }
            }
            return "MAU is preparing update files for an application."
        }

        // Calling remoteObjectProxy with Current App States
        if lowerMessage.contains("calling remoteobjectproxy with current app states") {
            let pattern = #"(\w+)\s*=\s*\{"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count))
                let appIds = matches.compactMap { match -> String? in
                    if let appRange = Range(match.range(at: 1), in: message) {
                        return String(message[appRange])
                    }
                    return nil
                }
                if !appIds.isEmpty {
                    let appNames = appIds.map { MicrosoftApp.fromAppIdString($0).rawValue }.joined(separator: ", ")
                    return "MAU is checking the current status of installed applications, including: \(appNames)."
                }
            }
            return "MAU is checking the status of currently installed applications."
        }
        
        // Updating Application State for App
        if lowerMessage.contains("updating application state for app") {
            let pattern = #"App:\s*(\w+)\s*to:\s*(\d+)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: message.utf16.count)
                if let match = regex.firstMatch(in: message, options: [], range: range) {
                    if let appRange = Range(match.range(at: 1), in: message),
                       let stateRange = Range(match.range(at: 2), in: message) {
                        let appId = String(message[appRange])
                        let state = String(message[stateRange])
                        let appEnum = MicrosoftApp.fromAppIdString(appId)
                        let appName = appEnum == .other ? appId : appEnum.rawValue
                        return "The update process for \(appName) has moved to a new state (State: \(state))."
                    }
                }
            }
             return "The update process for an application has moved to a new state."
        }

        // Fetching/Download operations
        if lowerMessage.contains("fetching file") || lowerMessage.contains("download") {
            if lowerMessage.contains("attempt") {
                return "MAU is attempting to download a file from their servers as part of the update process."
            }
            if lowerMessage.contains("success") {
                return "MAU successfully downloaded an update file. The process is progressing normally."
            }
            if lowerMessage.contains("failed") {
                return "MAU failed to download a required file. This could be due to network issues or server problems."
            }
            if lowerMessage.contains("progress") {
                return "MAU is currently downloading an update."
            }
        }
        
        // Installation operations
        if lowerMessage.contains("install") {
            if lowerMessage.contains("success") || lowerMessage.contains("completed") {
                return "MAU successfully installed an update. The application is now up to date."
            }
            if lowerMessage.contains("failed") {
                return "MAU failed to install an update. This could be due to permission issues or file conflicts."
            }
            if lowerMessage.contains("progress") {
                return "MAU is currently installing an update. Please do not close the application."
            }
        }
        
        // Final fallback - return the original message if it's short and clear
        if message.count < 100 {
            return message
        }
        
        // For very long technical messages, provide a generic but helpful explanation
        return "MAU performed a system operation. This is normal background activity to keep your applications updated and secure."
    }
    
    static func parse(line: String) -> LogEntry? {
        guard !line.isEmpty else { return nil }
        
        let pattern = #"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+\[([^\]]+)\]\s+<([^>]+)>\s+([^:]+):\s+(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        
        let timestampString = nsLine.substring(with: match.range(at: 1))
        let app = nsLine.substring(with: match.range(at: 2))
        let level = nsLine.substring(with: match.range(at: 3))
        let logType = nsLine.substring(with: match.range(at: 4))
        let jsonString = nsLine.substring(with: match.range(at: 5))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = dateFormatter.date(from: timestampString) ?? Date()
        
        var message = ""
        var humanReadableMessage = ""
        
        if let jsonData = jsonString.data(using: .utf8) {
            if logType.contains("NOT.COLLECTED") {
                if let payload = try? JSONDecoder().decode(PayloadData.self, from: jsonData) {
                    message = payload.Payload ?? ""
                    humanReadableMessage = createSimpleExplanation(for: message, app: app, level: level)
                }
            } else if logType.contains("ErrorsAndWarnings") {
                if let error = try? JSONDecoder().decode(ErrorData.self, from: jsonData) {
                    var parts: [String] = []
                    
                    if let errorMsg = error.Error { 
                        parts.append(errorMsg)
                    }
                    if let op = error.Operation { 
                        parts.append("[\(op)]")
                    }
                    if let appID = error.AppID { 
                        parts.append("App: \(appID)")
                    }
                    if let code = error.ErrorCode { 
                        parts.append("Code: \(code)")
                    }
                    
                    message = parts.joined(separator: " | ")
                    humanReadableMessage = createSimpleExplanation(for: message, app: app, level: level)
                }
            } else {
                // Try to parse as general JSON and create human-readable format
                if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    var humanParts: [String] = []
                    for (key, value) in json {
                        let formattedKey = key.replacingOccurrences(of: "_", with: " ").capitalized
                        humanParts.append("\(formattedKey): \(value)")
                    }
                    message = humanParts.joined(separator: " | ")
                    humanReadableMessage = createSimpleExplanation(for: message, app: app, level: level)
                }
            }
        }
        
        // If no human-readable message was created, use CEO explanation
        if humanReadableMessage.isEmpty {
            let originalMessage = message.isEmpty ? jsonString : message
            humanReadableMessage = createSimpleExplanation(for: originalMessage, app: app, level: level)
        }
        
        return LogEntry(
            timestamp: date,
            timestampString: timestampString,
            app: app,
            level: level,
            message: message.isEmpty ? jsonString : message,
            humanReadableMessage: humanReadableMessage,
            rawLine: line,
            logType: logType
        )
    }
}
