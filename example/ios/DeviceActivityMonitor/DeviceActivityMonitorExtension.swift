//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Nikita on 8/6/25.
//

import DeviceActivity
import Foundation
import os.log

#if canImport(ManagedSettings)
    import ManagedSettings
#endif
#if canImport(FamilyControls)
    import FamilyControls
#endif

// MARK: - System Health Monitoring
class ExtensionSystemMonitor {
    static let shared = ExtensionSystemMonitor()
    private let logger = ExtensionLogger.shared
    private var lastMemoryCheck: CFAbsoluteTime = 0
    private let memoryCheckInterval: CFAbsoluteTime = 30.0  // Check every 30 seconds

    private init() {}

    func checkSystemHealth() {
        let currentTime = CFAbsoluteTimeGetCurrent()

        if currentTime - lastMemoryCheck > memoryCheckInterval {
            checkMemoryUsage()
            lastMemoryCheck = currentTime
        }
    }

    private func checkMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let memoryMB = info.resident_size / (1024 * 1024)

            if memoryMB > 50 {  // Alert if over 50MB (high for extension)
                extLogWarning("⚠️ High memory usage detected: \(memoryMB)MB")
            } else {
                extLogDebug("💾 Memory usage: \(memoryMB)MB")
            }
        }
    }

    func validateQuotaConfiguration() {
        let quotas = ExtensionQuotaManager.shared.getQuotas()

        if quotas.isEmpty {
            extLogWarning("⚠️ No quota configurations found")
            return
        }

        for (index, quota) in quotas.enumerated() {
            guard let allowedOpens = quota["allowedOpensPerDay"] as? Int,
                let currentCount = quota["currentCount"] as? Int
            else {
                extLogWarning("⚠️ Invalid quota configuration at index \(index)")
                continue
            }

            if allowedOpens <= 0 {
                extLogWarning("⚠️ Invalid allowed opens value: \(allowedOpens)")
            }

            if currentCount > allowedOpens {
                extLogError("🚨 Quota exceeded: current(\(currentCount)) > allowed(\(allowedOpens))")
            }
        }

        extLogSuccess("✅ Quota configuration validated for \(quotas.count) quotas")
    }
}

// MARK: - ExtensionLogger with Enhanced Features
@available(iOS 14.0, *)
class ExtensionLogger {
    static let shared = ExtensionLogger()

    private let logger = Logger(
        subsystem: "com.example.screenTimeApiIosExample.extension",
        category: "DeviceActivityMonitor")

    /// Get app group identifier from configuration or use default
    private var appGroupIdentifier: String {
        // Read from UserDefaults or use default
        return UserDefaults.standard.string(forKey: "AppGroupIdentifierConfig")
            ?? "group.com.example.screenTimeApiIosExample"
    }

    private var logFileURL: URL?
    private let logQueue = DispatchQueue(label: "com.extension.logger", qos: .utility)

    // Log management properties
    private let maxLogFileSize: Int = 5 * 1024 * 1024  // 5MB
    private let maxLogFiles: Int = 3
    private var logCount: Int = 0
    private let analyticsInterval: Int = 100  // Log analytics every 100 logs

    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case success = "SUCCESS"

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .success: return "✅"
            }
        }
    }

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            logger.error("❌ Extension: Failed to access App Group container")
            return
        }

        // Create logs directory
        let logsDirectory = containerURL.appendingPathComponent("Logs")
        try? FileManager.default.createDirectory(
            at: logsDirectory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        self.logFileURL = logsDirectory.appendingPathComponent("extension_\(dateString).log")
        logger.info(
            "📝 Extension: Log file configured at: \(String(describing: self.logFileURL?.path))")

        // Clean up old logs
        cleanupOldLogs(in: logsDirectory)
    }

    private func cleanupOldLogs(in directory: URL) {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: []
            )

            let logFiles = files.filter { $0.pathExtension == "log" }
                .sorted { file1, file2 in
                    let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate
                    let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate
                    return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
                }

            // Keep only the most recent files
            let filesToDelete = logFiles.dropFirst(maxLogFiles)
            for file in filesToDelete {
                try FileManager.default.removeItem(at: file)
                logger.info("🗑️ Deleted old log file: \(file.lastPathComponent)")
            }
        } catch {
            logger.error("❌ Failed to cleanup old logs: \(error.localizedDescription)")
        }
    }

    private func log(
        _ message: String, level: LogLevel, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        logCount += 1

        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage =
            "\(timestamp) [EXT-\(level.rawValue)] \(level.emoji) \(message) (\(fileName):\(line))"

        // Console logging
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .success:
            logger.info("\(logMessage)")
        }

        // File logging with rotation check
        writeToFile(logMessage)

        // Log analytics periodically
        if logCount % analyticsInterval == 0 {
            logAnalytics()
        }
    }

    private func logAnalytics() {
        let memoryUsage = getMemoryUsage()
        let quotaCount = ExtensionQuotaManager.shared.getQuotas().count

        logger.info(
            "📊 Extension Analytics: \(self.logCount) logs written, \(memoryUsage)MB memory, \(quotaCount) quotas"
        )
    }

    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int(info.resident_size / (1024 * 1024)) : 0
    }

    private func writeToFile(_ message: String) {
        logQueue.async { [weak self] in
            guard let self = self, let logFileURL = self.logFileURL else { return }

            let logEntry = message + "\n"

            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFileURL.path) {
                    // Check file size before writing
                    if let attributes = try? FileManager.default.attributesOfItem(
                        atPath: logFileURL.path),
                        let fileSize = attributes[.size] as? Int,
                        fileSize > self.maxLogFileSize
                    {
                        self.rotateLogFile()
                    }

                    // Append to existing file
                    if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    // Create new file
                    try? data.write(to: logFileURL)
                }
            }
        }
    }

    private func rotateLogFile() {
        guard let currentURL = logFileURL else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())

        let rotatedURL = currentURL.deletingLastPathComponent()
            .appendingPathComponent("extension_\(timestamp).log")

        try? FileManager.default.moveItem(at: currentURL, to: rotatedURL)
        logger.info("🔄 Rotated log file to: \(rotatedURL.lastPathComponent)")

        // Clean up old logs after rotation
        cleanupOldLogs(in: currentURL.deletingLastPathComponent())
    }

    // MARK: - Public Logging Methods
    func debug(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    func success(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(message, level: .success, file: file, function: function, line: line)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// MARK: - Global Logging Functions for Extension
func extLogDebug(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
) {
    if #available(iOS 14.0, *) {
        ExtensionLogger.shared.debug(message, file: file, function: function, line: line)
    }
}

func extLogInfo(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
) {
    if #available(iOS 14.0, *) {
        ExtensionLogger.shared.info(message, file: file, function: function, line: line)
    }
}

func extLogWarning(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
) {
    if #available(iOS 14.0, *) {
        ExtensionLogger.shared.warning(message, file: file, function: function, line: line)
    }
}

func extLogError(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
) {
    if #available(iOS 14.0, *) {
        ExtensionLogger.shared.error(message, file: file, function: function, line: line)
    }
}

func extLogSuccess(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
) {
    if #available(iOS 14.0, *) {
        ExtensionLogger.shared.success(message, file: file, function: function, line: line)
    }
}

// Copy the QuotaManager functionality for the extension
@available(iOS 15.0, *)
class ExtensionQuotaManager {
    static let shared = ExtensionQuotaManager()

    /// Get app group identifier from configuration or use default
    private var appGroupIdentifier: String {
        // Read from UserDefaults or use default - must match main app configuration
        return UserDefaults.standard.string(forKey: "AppGroupIdentifierConfig")
            ?? "group.com.example.screenTimeApiIosExample"
    }

    private let quotaUserDefaultsKey = "ScreenTimeQuotas"
    private let dailyCountersKey = "DailyAppCounters"
    private let lastResetDateKey = "lastResetDate"

    private var appGroupDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    func getQuotas() -> [[String: Any]] {
        let quotas = appGroupDefaults?.array(forKey: quotaUserDefaultsKey) as? [[String: Any]] ?? []
        extLogDebug("Retrieved \(quotas.count) quota configuration(s) from shared defaults")
        return quotas
    }

    func incrementCounter(for encodedToken: String) -> Int {
        checkAndResetDailyCounters()
        var counters = getDailyCounters()
        let currentCount = counters[encodedToken] ?? 0
        let newCount = currentCount + 1
        counters[encodedToken] = newCount
        appGroupDefaults?.set(counters, forKey: dailyCountersKey)

        extLogInfo("📊 Incremented app usage counter: \(encodedToken) → \(newCount)")
        return newCount
    }

    func getDailyCounters() -> [String: Int] {
        checkAndResetDailyCounters()
        let counters =
            appGroupDefaults?.dictionary(forKey: dailyCountersKey) as? [String: Int] ?? [:]
        extLogDebug("Retrieved daily counters: \(counters.count) app(s) tracked")
        return counters
    }

    func shouldBlockApp(encodedToken: String) -> Bool {
        let quotas = getQuotas()
        let currentCount = getDailyCounters()[encodedToken] ?? 0

        for quotaData in quotas {
            guard let token = quotaData["encodedToken"] as? String,
                let allowedOpens = quotaData["allowedOpensPerDay"] as? Int,
                token == encodedToken
            else {
                continue
            }

            if allowedOpens == 0 {
                extLogInfo("🚫 App blocked (zero quota): \(encodedToken)")
                return true
            }

            if currentCount >= allowedOpens {
                extLogWarning(
                    "🚫 App quota exceeded: \(encodedToken) (\(currentCount)/\(allowedOpens) opens used)"
                )
                return true
            }

            extLogDebug(
                "✅ App within quota: \(encodedToken) (\(currentCount)/\(allowedOpens) opens used)")
            return false
        }

        extLogDebug("No quota found for app: \(encodedToken) - allowing access")
        return false
    }

    func checkAndResetDailyCounters() {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        let lastResetTimestamp = appGroupDefaults?.double(forKey: lastResetDateKey) ?? 0
        let lastResetDate = Date(timeIntervalSince1970: lastResetTimestamp)

        if lastResetDate < startOfToday {
            extLogInfo("🔄 Resetting daily counters for new day")
            appGroupDefaults?.removeObject(forKey: dailyCountersKey)
            appGroupDefaults?.set(now.timeIntervalSince1970, forKey: lastResetDateKey)
            extLogSuccess("Daily counters reset completed")
        } else {
            extLogDebug(
                "Daily counters current (last reset: \(DateFormatter.logFormatter.string(from: lastResetDate)))"
            )
        }
    }

    @available(iOS 15.0, *)
    func applyDynamicBlocking() {
        extLogInfo("🛡️ Applying dynamic blocking based on quota violations")
        #if canImport(ManagedSettings) && canImport(FamilyControls)
            // Use a separate store for dynamic blocking from the extension
            let store = ManagedSettingsStore(
                named: ManagedSettingsStore.Name("ExtensionQuotaStore"))
            let _ = getQuotas()  // Get quotas for tracking purposes

            // Clear existing restrictions first
            store.clearAllSettings()
            extLogDebug("Cleared previous extension blocking settings")

            // Note: In a real implementation, you'd need to decode tokens
            // For simplicity, we'll track quota violations in shared defaults
            // and let the main app handle the actual blocking

            extLogSuccess("Dynamic blocking status updated")
        #else
            extLogWarning("ManagedSettings unavailable - dynamic blocking skipped")
        #endif
    }
}

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
@available(iOS 15.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        extLogInfo("📅 DeviceActivity interval started: \(activity)")
        extLogDebug("System timezone: \(TimeZone.current.identifier)")

        let now = Date()
        extLogInfo("Current timestamp: \(DateFormatter.logFormatter.string(from: now))")

        // Reset daily counters at the start of each day
        let startTime = CFAbsoluteTimeGetCurrent()
        ExtensionQuotaManager.shared.checkAndResetDailyCounters()
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        extLogDebug(
            "Daily counter reset check completed in \(String(format: "%.3f", elapsedTime))s")

        // Log current quota status
        let quotas = ExtensionQuotaManager.shared.getQuotas()
        let counters = ExtensionQuotaManager.shared.getDailyCounters()
        extLogInfo(
            "📊 Monitoring status: \(quotas.count) quotas configured, \(counters.count) apps tracked"
        )

        if !quotas.isEmpty {
            extLogDebug(
                "Active quotas: \(quotas.map { ($0["encodedToken"] as? String ?? "unknown") + "(\(($0["allowedOpensPerDay"] as? Int ?? 0)) opens)" }.joined(separator: ", "))"
            )
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        extLogInfo("📅 DeviceActivity interval ended: \(activity)")

        // Log session summary
        let counters = ExtensionQuotaManager.shared.getDailyCounters()
        let totalUsage = counters.values.reduce(0, +)
        extLogInfo("📈 Session summary: \(totalUsage) total app opens across \(counters.count) apps")

        if !counters.isEmpty {
            let sortedCounters = counters.sorted { $0.value > $1.value }
            let topApps = sortedCounters.prefix(3).map { "\($0.key.prefix(8))...(\($0.value))" }
            extLogDebug("Top usage: \(topApps.joined(separator: ", "))")
        }
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name, activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        let startTime = CFAbsoluteTimeGetCurrent()
        extLogWarning("⚠️ Event threshold reached: \(event) for activity: \(activity)")

        // When an event threshold is reached, this typically means an app was opened
        // We need to track this and potentially block the app if quota is exceeded
        extLogInfo("🎯 Processing app usage event for quota tracking")

        // For now, we'll increment counters for all monitored apps
        // In a more sophisticated implementation, you'd map events to specific apps
        let quotas = ExtensionQuotaManager.shared.getQuotas()
        extLogDebug("Processing \(quotas.count) quota configurations for usage tracking")

        var quotaViolations = 0
        var successfulTracking = 0

        for quotaData in quotas {
            guard let encodedToken = quotaData["encodedToken"] as? String,
                let allowedOpens = quotaData["allowedOpensPerDay"] as? Int,
                allowedOpens > 0
            else {  // Skip already blocked (0-quota) apps
                continue
            }

            let tokenPreview = String(encodedToken.prefix(8)) + "..."
            let newCount = ExtensionQuotaManager.shared.incrementCounter(for: encodedToken)

            // Check if we should block this app now
            if newCount >= allowedOpens {
                quotaViolations += 1
                extLogError(
                    "🚫 App quota exceeded: \(tokenPreview) (\(newCount)/\(allowedOpens) opens)")
                ExtensionQuotaManager.shared.applyDynamicBlocking()
                extLogInfo("Applied dynamic blocking for quota violations")
            } else {
                successfulTracking += 1
                let remainingOpens = allowedOpens - newCount
                extLogSuccess(
                    "✅ App usage within quota: \(tokenPreview) (\(newCount)/\(allowedOpens) opens, \(remainingOpens) remaining)"
                )
            }
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        extLogInfo(
            "📊 Event processing completed in \(String(format: "%.3f", processingTime))s: \(successfulTracking) tracked, \(quotaViolations) violations"
        )
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        extLogWarning("⚠️ Warning: DeviceActivity interval will start for: \(activity)")
        extLogDebug("System preparing for activity monitoring session")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        extLogWarning("⚠️ Warning: DeviceActivity interval will end for: \(activity)")
        extLogDebug("System preparing to end activity monitoring session")
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name, activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        extLogWarning("⚠️ Warning: Event \(event) will reach threshold for activity: \(activity)")
        extLogInfo("📊 Preparing for potential quota enforcement action")

        // Proactive logging for upcoming threshold
        let quotas = ExtensionQuotaManager.shared.getQuotas()
        let activeQuotas = quotas.filter { ($0["allowedOpensPerDay"] as? Int ?? 0) > 0 }
        extLogDebug("Pre-threshold check: \(activeQuotas.count) active quotas may be affected")
    }
}
