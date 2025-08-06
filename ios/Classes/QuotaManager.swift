//
//  QuotaManager.swift
//  screen_time_api_ios
//
//  Created by Nikita on 8/6/25.
//

import Foundation

#if canImport(ManagedSettings)
    import ManagedSettings
#endif
#if canImport(FamilyControls)
    import FamilyControls
#endif

/// Shared quota management between main app and extension
@available(iOS 15.0, *)
class QuotaManager {
    static let shared = QuotaManager()

    private let quotaUserDefaultsKey = "ScreenTimeQuotas"
    private let dailyCountersKey = "DailyAppCounters"
    private let lastResetDateKey = "lastResetDate"

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

    private var appGroupDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {
        // Listen for app group identifier changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appGroupIdentifierChanged),
            name: NSNotification.Name("AppGroupIdentifierChanged"),
            object: nil
        )
    }

    @objc private func appGroupIdentifierChanged() {
        print(
            "🔄 App group identifier changed, QuotaManager will use new identifier: \(appGroupIdentifier)"
        )
    }

    // MARK: - Quota Configuration

    func getQuotas() -> [[String: Any]] {
        return appGroupDefaults?.array(forKey: quotaUserDefaultsKey) as? [[String: Any]] ?? []
    }

    func saveQuotas(_ quotas: [[String: Any]]) {
        appGroupDefaults?.set(quotas, forKey: quotaUserDefaultsKey)
    }

    // MARK: - Daily Counters

    func getDailyCounters() -> [String: Int] {
        checkAndResetDailyCounters()
        return appGroupDefaults?.dictionary(forKey: dailyCountersKey) as? [String: Int] ?? [:]
    }

    func incrementCounter(for encodedToken: String) -> Int {
        checkAndResetDailyCounters()
        var counters = getDailyCounters()
        let currentCount = counters[encodedToken] ?? 0
        let newCount = currentCount + 1
        counters[encodedToken] = newCount
        appGroupDefaults?.set(counters, forKey: dailyCountersKey)

        print("📊 Incremented counter for \(encodedToken): \(newCount)")
        return newCount
    }

    func getCounter(for encodedToken: String) -> Int {
        checkAndResetDailyCounters()
        let counters = getDailyCounters()
        return counters[encodedToken] ?? 0
    }

    private func checkAndResetDailyCounters() {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        let lastResetTimestamp = appGroupDefaults?.double(forKey: lastResetDateKey) ?? 0
        let lastResetDate = Date(timeIntervalSince1970: lastResetTimestamp)

        // If last reset was before today, reset counters
        if lastResetDate < startOfToday {
            print("🔄 Resetting daily counters for new day")
            appGroupDefaults?.removeObject(forKey: dailyCountersKey)
            appGroupDefaults?.set(now.timeIntervalSince1970, forKey: lastResetDateKey)
        }
    }

    // MARK: - Quota Enforcement

    func shouldBlockApp(encodedToken: String) -> Bool {
        let quotas = getQuotas()
        let currentCount = getCounter(for: encodedToken)

        for quotaData in quotas {
            guard let token = quotaData["encodedToken"] as? String,
                let allowedOpens = quotaData["allowedOpensPerDay"] as? Int,
                token == encodedToken
            else {
                continue
            }

            // If quota is 0, always block
            if allowedOpens == 0 {
                return true
            }

            // If current count >= allowed opens, block
            if currentCount >= allowedOpens {
                print("🚫 Blocking app \(encodedToken): \(currentCount)/\(allowedOpens) opens used")
                return true
            }

            return false
        }

        return false
    }

    func getQuotaInfo(for encodedToken: String) -> (allowed: Int, used: Int)? {
        let quotas = getQuotas()
        let currentCount = getCounter(for: encodedToken)

        for quotaData in quotas {
            guard let token = quotaData["encodedToken"] as? String,
                let allowedOpens = quotaData["allowedOpensPerDay"] as? Int,
                token == encodedToken
            else {
                continue
            }

            return (allowed: allowedOpens, used: currentCount)
        }

        return nil
    }

    // MARK: - App Blocking

    @available(iOS 16.0, *)
    func applyDynamicBlocking() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("QuotaStore"))
            let quotas = getQuotas()
            let tokenManager = TokenManager()

            var applicationsToBlock: Set<ApplicationToken> = []
            var categoriesToBlock: Set<ActivityCategoryToken> = []
            var webDomainsToBlock: Set<WebDomainToken> = []

            for quotaData in quotas {
                guard let encodedToken = quotaData["encodedToken"] as? String,
                    let tokenType = quotaData["tokenType"] as? String
                else {
                    continue
                }

                if shouldBlockApp(encodedToken: encodedToken) {
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
                }
            }

            // Apply dynamic blocking
            store.shield.applications = applicationsToBlock.isEmpty ? nil : applicationsToBlock
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
                categoriesToBlock)
            store.shield.webDomains = webDomainsToBlock.isEmpty ? nil : webDomainsToBlock
            store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.specific(
                categoriesToBlock)

            print(
                "🛡️ Applied dynamic blocking: \(applicationsToBlock.count) apps, \(categoriesToBlock.count) categories, \(webDomainsToBlock.count) domains"
            )
        #endif
    }
}
