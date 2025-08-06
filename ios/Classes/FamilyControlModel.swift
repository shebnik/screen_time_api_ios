//
//  FamilyControlModel.swift
//  screen_time_api_ios
//
//  Created by Kei Fujikawa on 2023/10/11.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

class FamilyControlModel: ObservableObject {
    static let shared = FamilyControlModel()

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    private let userDefaultsKey = "ScreenTimeSelection"
    private let quotaUserDefaultsKey = "ScreenTimeQuotas"
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    /// Get the current app group identifier from ConfigurationManager or use default
    private var appGroupIdentifier: String {
        // Try to get from ConfigurationManager if available, otherwise use default
        if let config = NSClassFromString("ConfigurationManager") as? NSObject.Type {
            return (config.value(forKey: "shared") as? NSObject)?.value(
                forKey: "appGroupIdentifier") as? String
                ?? "group.com.example.screenTimeApiIosExample"
        }
        return "group.com.example.screenTimeApiIosExample"
    }

    private init() {
        selectionToDiscourage = savedSelection() ?? FamilyActivitySelection()
        tempSelection = selectionToDiscourage
    }

    @Published var selectionToDiscourage = FamilyActivitySelection()
    @Published var tempSelection = FamilyActivitySelection()  // For picker interaction without saving

    func authorize() async throws {
        if #available(iOS 16.0, *) {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } else {
            AuthorizationCenter.shared.requestAuthorization(completionHandler: { _ in })
        }
    }

    func discourage(
        applications: Set<ApplicationToken>, categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(
                categories
            )
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        store.shield.webDomainCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(
                categories
            )
    }

    func getDiscouragedApps() -> [String: Any] {
        // Get currently discouraged items from the ManagedSettingsStore
        let applications = store.shield.applications ?? Set<ApplicationToken>()
        let webDomains = store.shield.webDomains ?? Set<WebDomainToken>()

        // Extract categories from the policy
        var categories = Set<ActivityCategoryToken>()
        if case let .specific(categorySet, except: _) = store.shield.applicationCategories {
            categories = categorySet
        }

        // Also check web domain categories
        var webCategories = Set<ActivityCategoryToken>()
        if case let .specific(categorySet, except: _) = store.shield.webDomainCategories {
            webCategories = categorySet
        }

        // Combine categories (they should be the same, but merge to be safe)
        let allCategories = categories.union(webCategories)

        let tokenManager = TokenManager()

        var applicationTokens: [String] = []
        for token in applications {
            do {
                applicationTokens.append(try tokenManager.encodeApplicationToken(token))
            } catch {
                logError("⚠️ Failed to encode application token: \(error)")
            }
        }

        var categoryTokens: [String] = []
        for token in allCategories {
            do {
                categoryTokens.append(try tokenManager.encodeCategoryToken(token))
            } catch {
                logError("⚠️ Failed to encode category token: \(error)")
            }
        }

        var webDomainTokens: [String] = []
        for token in webDomains {
            do {
                webDomainTokens.append(try tokenManager.encodeWebDomainToken(token))
            } catch {
                logError("⚠️ Failed to encode web domain token: \(error)")
            }
        }

        return [
            "applicationTokens": applicationTokens,
            "categoryTokens": categoryTokens,
            "webDomainTokens": webDomainTokens,
        ]
    }

    func encourageAll() {
        store.shield.applications = []
        store.shield.applicationCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(
                []
            )
        store.shield.webDomains = []
        store.shield.webDomainCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(
                []
            )
        // Also clear adult website blocking
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none

        // Clear saved quotas using QuotaManager
        QuotaManager.shared.saveQuotas([])

        // Stop all monitoring
        Task {
            try? await stopAllMonitoring()
        }
    }

    func saveSelection(selection: FamilyActivitySelection) {
        let defaults = UserDefaults.standard
        defaults.set(
            try? encoder.encode(selection),
            forKey: userDefaultsKey
        )
    }

    func saveCurrentSelection() {
        selectionToDiscourage = tempSelection
        saveSelection(selection: selectionToDiscourage)
    }

    func resetTempSelection() {
        tempSelection = selectionToDiscourage
        logInfo("🔄 Selection reset to saved state")
    }

    func clearTempSelection() {
        tempSelection = FamilyActivitySelection()
        logInfo("🗑️ Temporary selection cleared")
    }

    func clearAllSelections() {
        tempSelection = FamilyActivitySelection()
        selectionToDiscourage = FamilyActivitySelection()
        saveSelection(selection: selectionToDiscourage)
        logInfo("🧹 All selections cleared and saved")
    }

    func savedSelection() -> FamilyActivitySelection? {
        let defaults = UserDefaults.standard

        guard let data = defaults.data(forKey: userDefaultsKey) else {
            return nil
        }

        return try? decoder.decode(
            FamilyActivitySelection.self,
            from: data
        )
    }

    // MARK: - Web Content Blocking

    func setWebContentBlocking(
        adultContentEnabled: Bool,
        blockedDomains: [String] = []
    ) async throws {
        logInfo(
            "🔧 Setting web content blocking - adult: \(adultContentEnabled), blocked: \(blockedDomains.count)"
        )

        // Store configuration in UserDefaults for persistence
        let appGroup = UserDefaults(suiteName: appGroupIdentifier)
        appGroup?.set(blockedDomains, forKey: "blockedDomains")
        appGroup?.set(adultContentEnabled, forKey: "adultContentEnabled")

        if adultContentEnabled {
            if !blockedDomains.isEmpty {
                // Use auto() with additional blocked domains
                let webDomains = Set(blockedDomains.map { WebDomain(domain: $0) })
                store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.auto(
                    webDomains)
                logInfo(
                    "🚫 Adult content filter enabled with \(blockedDomains.count) additional blocked domains"
                )
            } else {
                // Just adult content blocking
                store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.auto()
                logInfo("🚫 Adult content filter enabled")
            }
        } else {
            if !blockedDomains.isEmpty {
                // Use specific blocking for custom domains only
                let webDomains = Set(blockedDomains.map { WebDomain(domain: $0) })
                store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.specific(
                    webDomains)
                logInfo("🚫 Custom domain blocking enabled for \(blockedDomains.count) domains")
            } else {
                // No filtering
                store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
                logInfo("✅ All web content filtering disabled")
            }
        }

        logSuccess("Web content blocking configuration applied successfully")
    }

    // Convenience method for simple adult website blocking toggle
    func setAdultWebsiteBlocking(enabled: Bool) {
        // Get existing blocked domains from UserDefaults
        let appGroup = UserDefaults(suiteName: appGroupIdentifier)
        let blockedDomains = appGroup?.array(forKey: "blockedDomains") as? [String] ?? []

        // Use the unified method
        Task {
            try? await setWebContentBlocking(
                adultContentEnabled: enabled,
                blockedDomains: blockedDomains
            )
        }
    }

    func getAdultWebsiteBlocking() -> Bool {
        // Check if adult content is enabled from UserDefaults
        let appGroup = UserDefaults(suiteName: appGroupIdentifier)
        let adultContentEnabled = appGroup?.bool(forKey: "adultContentEnabled") ?? false

        logInfo("📋 Adult website blocking status: \(adultContentEnabled)")
        return adultContentEnabled
    }

    func getWebContentBlocking() async throws -> [String: Any] {
        logInfo("📋 Getting web content blocking configuration")

        // Get stored configuration from UserDefaults
        let appGroup = UserDefaults(suiteName: appGroupIdentifier)
        let blockedDomains = appGroup?.array(forKey: "blockedDomains") as? [String] ?? []
        let adultContentEnabled = appGroup?.bool(forKey: "adultContentEnabled") ?? false

        // Check current filter policy
        let currentFilter = store.webContent.blockedByFilter
        let isFilterActive = currentFilter != WebContentSettings.FilterPolicy.none

        let result: [String: Any] = [
            "adultContentEnabled": adultContentEnabled,
            "blockedDomains": blockedDomains,
            "isActive": isFilterActive,
        ]

        logInfo(
            "📋 Current web content blocking - adult: \(adultContentEnabled), blocked: \(blockedDomains.count), active: \(isFilterActive)"
        )

        return result
    }

    // MARK: - App Quota Management

    func setAppQuotas(with arguments: [String: Any]) async throws {
        guard let appQuotasData = arguments["appQuotas"] as? [[String: Any]] else {
            throw NSError(
                domain: "QuotaError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid quota data"])
        }

        // Save quota configuration using QuotaManager
        QuotaManager.shared.saveQuotas(appQuotasData)

        // Stop any existing monitoring
        try await stopAllMonitoring()

        // Separate apps by quota type
        var applicationsToBlock: Set<ApplicationToken> = []
        var categoriesToBlock: Set<ActivityCategoryToken> = []
        var webDomainsToBlock: Set<WebDomainToken> = []
        var applicationsToMonitor: Set<ApplicationToken> = []
        var categoriesToMonitor: Set<ActivityCategoryToken> = []
        var webDomainsToMonitor: Set<WebDomainToken> = []

        let tokenManager = TokenManager()

        for quotaData in appQuotasData {
            guard let encodedToken = quotaData["encodedToken"] as? String,
                let tokenType = quotaData["tokenType"] as? String,
                let allowedOpens = quotaData["allowedOpensPerDay"] as? Int
            else {
                continue
            }

            if allowedOpens == 0 {
                // Block completely
                switch tokenType {
                case "application":
                    if let token = try? tokenManager.decodeApplicationToken(encodedToken) {
                        applicationsToBlock.insert(token)
                    }
                case "category":
                    if let token = try? tokenManager.decodeCategoryToken(encodedToken) {
                        categoriesToBlock.insert(token)
                    }
                case "webDomain":
                    if let token = try? tokenManager.decodeWebDomainToken(encodedToken) {
                        webDomainsToBlock.insert(token)
                    }
                default:
                    break
                }
            } else {
                // Monitor for quota enforcement
                switch tokenType {
                case "application":
                    if let token = try? tokenManager.decodeApplicationToken(encodedToken) {
                        applicationsToMonitor.insert(token)
                    }
                case "category":
                    if let token = try? tokenManager.decodeCategoryToken(encodedToken) {
                        categoriesToMonitor.insert(token)
                    }
                case "webDomain":
                    if let token = try? tokenManager.decodeWebDomainToken(encodedToken) {
                        webDomainsToMonitor.insert(token)
                    }
                default:
                    break
                }
            }
        }

        // Apply blocking for 0-quota apps using main store
        discourage(
            applications: applicationsToBlock,
            categories: categoriesToBlock,
            webDomains: webDomainsToBlock
        )

        // Set up monitoring for non-zero quotas
        if !applicationsToMonitor.isEmpty || !categoriesToMonitor.isEmpty
            || !webDomainsToMonitor.isEmpty
        {
            try setupDeviceActivityMonitoring(
                applications: applicationsToMonitor,
                categories: categoriesToMonitor,
                webDomains: webDomainsToMonitor
            )
        }

        logInfo("✅ App quotas configured successfully")
    }

    private func setupDeviceActivityMonitoring(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) throws {
        let activityName = DeviceActivityName("QuotaMonitoring")

        // Create a simple schedule that runs all day, every day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Start basic monitoring - the extension will handle the actual tracking
        do {
            try center.startMonitoring(activityName, during: schedule)
            logInfo("✅ Started DeviceActivity monitoring for quota enforcement")
        } catch {
            logError("❌ Failed to start monitoring: \(error)")
            throw error
        }
    }

    private func stopAllMonitoring() async throws {
        let activities = center.activities
        for activity in activities {
            center.stopMonitoring([activity])
        }
        logInfo("🛑 Stopped all DeviceActivity monitoring")
    }

    func getAppQuotas() -> [String: Any] {
        if #available(iOS 15.0, *) {
            let appQuotas = QuotaManager.shared.getQuotas()
            let dailyCounters = QuotaManager.shared.getDailyCounters()

            return [
                "appQuotas": appQuotas,
                "dailyCounters": dailyCounters,
            ]
        } else {
            return ["appQuotas": []]
        }
    }
}
