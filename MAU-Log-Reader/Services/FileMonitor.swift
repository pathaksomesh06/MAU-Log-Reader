import Foundation
import Combine

class FileMonitor: NSObject, ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var isMonitoring = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    @Published var fileAccessStatus = "No file loaded"
    
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var currentPath: String?
    private var allEntries: [LogEntry] = []
    
    override init() {
        super.init()
    }
    
    func loadLatestLog() {
        let fm = FileManager.default
        let microsoftLogsPath = "/Library/Logs/Microsoft"
        
        guard fm.fileExists(atPath: microsoftLogsPath) else {
            DispatchQueue.main.async {
                self.fileAccessStatus = "❌ Microsoft logs folder not found"
            }
            return
        }
        
        do {
            let files = try fm.contentsOfDirectory(atPath: microsoftLogsPath)
            let logFiles = files.filter { $0.hasSuffix(".log") }
            
            guard !logFiles.isEmpty else {
                DispatchQueue.main.async {
                    self.fileAccessStatus = "❌ No log files found"
                }
                return
            }
            
            // Find latest modified log
            var latestFile: String?
            var latestDate = Date.distantPast
            
            for file in logFiles {
                let filePath = "\(microsoftLogsPath)/\(file)"
                if let attrs = try? fm.attributesOfItem(atPath: filePath),
                   let modDate = attrs[.modificationDate] as? Date,
                   modDate > latestDate {
                    latestDate = modDate
                    latestFile = file
                }
            }
            
            if let latest = latestFile {
                let fullPath = "\(microsoftLogsPath)/\(latest)"
                loadLog(from: fullPath)
            }
        } catch {
            DispatchQueue.main.async {
                self.fileAccessStatus = "❌ Error reading logs folder"
            }
        }
    }
    
    func loadLog(from path: String) {
        currentPath = path
        
        // Read file directly
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                
                var parsed: [LogEntry] = []
                for line in lines {
                    if !line.isEmpty, let entry = LogParser.parse(line: line) {
                        parsed.append(entry)
                    }
                }
                
                parsed.sort { $0.timestamp < $1.timestamp }
                
                DispatchQueue.main.async {
                    self.allEntries = parsed
                    self.entries = parsed
                    self.errorMessage = nil
                    self.lastUpdateTime = Date()
                    self.fileAccessStatus = "✅ Loaded: \(URL(fileURLWithPath: path).lastPathComponent)"
                    print("✅ Loaded \(parsed.count) entries from \(path)")
                }
                
                // Start monitoring after successful load
                self.startMonitoring(path: path)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error reading file: \(error.localizedDescription)"
                    self.entries = []
                    self.fileAccessStatus = "❌ Cannot read file"
                    print("❌ Error: \(error)")
                }
            }
        }
    }
    
    func startMonitoring(path: String) {
        stopMonitoring()
        
        // Use POSIX open() like IntuneLogReader does
        let fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("⚠️ Failed to open file descriptor for monitoring")
            return
        }
        
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: DispatchQueue.main
        )
        
        fileMonitor?.setEventHandler { [weak self] in
            self?.reloadFile()
        }
        
        fileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileMonitor?.resume()
        DispatchQueue.main.async {
            self.isMonitoring = true
        }
    }
    
    func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
        DispatchQueue.main.async {
            self.isMonitoring = false
        }
    }
    
    private func reloadFile() {
        guard let path = currentPath else { return }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            let newParsedEntries = lines.compactMap { LogParser.parse(line: $0) }
            
            let newEntries = newParsedEntries.filter { newEntry in
                !allEntries.contains { $0.rawLine == newEntry.rawLine }
            }
            
            if !newEntries.isEmpty {
                allEntries.append(contentsOf: newEntries)
                allEntries.sort { $0.timestamp < $1.timestamp }
                
                DispatchQueue.main.async {
                    self.entries = self.allEntries
                    self.lastUpdateTime = Date()
                    print("📥 Detected \(newEntries.count) new entries")
                }
            }
        } catch {
            print("⚠️ Error reloading file: \(error)")
        }
    }
    
    func clearEntries() {
        allEntries.removeAll()
        DispatchQueue.main.async {
            self.entries = []
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
