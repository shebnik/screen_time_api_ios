//
//  QuotaManager.swift
//  screen_time_api_ios
//
//  Created by Quota System Implementation
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Manages app quotas and daily usage tracking
class QuotaManager: ObservableObject {
    static let shared = QuotaManager()
    
    private init() {
        print("QuotaManager: Initializing...")
        loadQuotas()
        resetDailyUsageIfNeeded()
        print("QuotaManager: Initialization completed with \(quotas.count) quotas")
    }
    
    private let userDefaultsKey = "AppQuotas"
    private let lastResetDateKey = "LastQuotaResetDate"
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    private let deviceActivityCenter = DeviceActivityCenter()
    private let quotaActivityName = DeviceActivityName("QuotaMonitoring")
    
    @Published var quotas: [Int: AppQuotaData] = [:]
    @Published var selectedAppsForConfiguration: FamilyActivitySelection = FamilyActivitySelection()
    
    /// Data structure for storing app quota information
    struct AppQuotaData: Codable {
        let index: Int // Index in the selection array
        let tokenType: String // "application" or "category"
        let dailyLimit: Int
        var usedToday: Int
        
        var isOverQuota: Bool {
            return usedToday >= dailyLimit
        }
        
        var canOpen: Bool {
            return usedToday < dailyLimit
        }
        
        var remainingOpens: Int {
            return max(0, dailyLimit - usedToday)
        }
    }
    
    /// Set quotas for multiple apps and categories
    func setQuotas(_ quotaDict: [String: Any]) {
        print("QuotaManager: setQuotas called with: \(quotaDict)")
        guard let quotasList = quotaDict["quotas"] as? [[String: Any]] else { 
            print("QuotaManager: ERROR - No quotas array found in input")
            return 
        }
        
        print("QuotaManager: Processing \(quotasList.count) quota entries")
        var newQuotas: [Int: AppQuotaData] = [:]
        
        for (index, quotaMap) in quotasList.enumerated() {
            print("QuotaManager: Processing quota entry \(index): \(quotaMap)")
            guard let dailyLimit = quotaMap["dailyLimit"] as? Int else { 
                print("QuotaManager: ERROR - Invalid quota entry at index \(index): missing dailyLimit")
                continue 
            }
            
            let usedToday = quotaMap["usedToday"] as? Int ?? 0
            let tokenType = quotaMap["tokenType"] as? String ?? "application"
            
            print("QuotaManager: Adding quota - index: \(index), type: \(tokenType), limit: \(dailyLimit), used: \(usedToday)")
            
            newQuotas[index] = AppQuotaData(
                index: index,
                tokenType: tokenType,
                dailyLimit: dailyLimit,
                usedToday: usedToday
            )
        }
        
        quotas = newQuotas
        print("QuotaManager: Successfully set \(quotas.count) quotas")
        saveQuotas()
        
        // Start monitoring device activity for usage tracking
        startMonitoringActivity()
    }
    
    /// Get current quotas as a dictionary for Flutter
    func getQuotas() -> [String: Any] {
        print("QuotaManager: getQuotas called, returning \(quotas.count) quotas")
        let quotasList = quotas.values.map { quota in
            let quotaMap = [
                "index": quota.index,
                "tokenType": quota.tokenType,
                "dailyLimit": quota.dailyLimit,
                "usedToday": quota.usedToday
            ]
            print("QuotaManager: Returning quota - index: \(quota.index), type: \(quota.tokenType), limit: \(quota.dailyLimit), used: \(quota.usedToday)")
            return quotaMap
        }
        
        let result = ["quotas": quotasList]
        print("QuotaManager: getQuotas completed with \(quotasList.count) entries")
        return result
    }
    
    /// Apply quota-based blocking based on current usage
    func applyQuotaSettings() {
        print("QuotaManager: Starting applyQuotaSettings")
        print("QuotaManager: Current quotas count: \(quotas.count)")
        
        let store = ManagedSettingsStore()
        
        // Get the current selection from FamilyControlModel
        let currentSelection = FamilyControlModel.shared.selectionForQuotaConfiguration
        print("QuotaManager: Current selection - apps: \(currentSelection.applicationTokens.count), categories: \(currentSelection.categoryTokens.count)")
        
        // Convert app tokens to array for index-based access
        let appTokensArray = Array(currentSelection.applicationTokens)
        let categoryTokensArray = Array(currentSelection.categoryTokens)
        
        // Filter apps that are over quota using index-based lookup
        let overQuotaAppTokens = appTokensArray.enumerated().compactMap { (index, appToken) -> ApplicationToken? in
            if let quota = quotas[index], quota.tokenType == "application" {
                let isOverQuota = quota.isOverQuota
                print("QuotaManager: App index \(index) - quota: \(quota.dailyLimit), used: \(quota.usedToday), over quota: \(isOverQuota)")
                return isOverQuota ? appToken : nil
            }
            print("QuotaManager: App index \(index) - no quota found, not blocking")
            return nil
        }
        
        // Filter categories that are over quota using index-based lookup
        let overQuotaCategoryTokens = categoryTokensArray.enumerated().compactMap { (index, categoryToken) -> ActivityCategoryToken? in
            if let quota = quotas[index], quota.tokenType == "category" {
                let isOverQuota = quota.isOverQuota
                print("QuotaManager: Category index \(index) - quota: \(quota.dailyLimit), used: \(quota.usedToday), over quota: \(isOverQuota)")
                return isOverQuota ? categoryToken : nil
            }
            print("QuotaManager: Category index \(index) - no quota found, not blocking")
            return nil
        }
        
        print("QuotaManager: Blocking \(overQuotaAppTokens.count) apps and \(overQuotaCategoryTokens.count) categories that are over quota")
        
        // Apply shields only to over-quota apps
        if overQuotaAppTokens.isEmpty {
            print("QuotaManager: No apps to block, clearing app shields")
            store.shield.applications = nil
        } else {
            print("QuotaManager: Setting app shields for \(overQuotaAppTokens.count) apps")
            store.shield.applications = Set(overQuotaAppTokens)
        }
        
        // Apply shields only to over-quota categories
        if overQuotaCategoryTokens.isEmpty {
            print("QuotaManager: No categories to block, clearing category shields")
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific([])
        } else {
            print("QuotaManager: Setting category shields for \(overQuotaCategoryTokens.count) categories")
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(Set(overQuotaCategoryTokens))
        }
        
        // Clear web domain restrictions for quota-based management
        store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.specific([])
        
        print("QuotaManager: applyQuotaSettings completed")
    }
    
    /// Remove all quota-based restrictions
    func removeAllRestrictions() {
        print("QuotaManager: removeAllRestrictions called")
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific([])
        store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.specific([])
        
        // Stop monitoring
        stopMonitoringActivity()
        
        // Clear quotas
        print("QuotaManager: Clearing \(quotas.count) quotas")
        quotas.removeAll()
        selectedAppsForConfiguration = FamilyActivitySelection()
        saveQuotas()
        print("QuotaManager: removeAllRestrictions completed")
    }
    
    /// Track app usage (would be called when app is opened)
    func trackAppUsage(index: Int) {
        print("QuotaManager: trackAppUsage called for index: \(index)")
        guard var quota = quotas[index] else { 
            print("QuotaManager: No quota found for index: \(index)")
            return 
        }
        quota.usedToday += 1
        quotas[index] = quota
        print("QuotaManager: Updated usage for index: \(index) - now used: \(quota.usedToday)/\(quota.dailyLimit)")
        saveQuotas()
        
        // Reapply settings if this app just went over quota
        if quota.isOverQuota {
            print("QuotaManager: Index \(index) went over quota, reapplying settings")
            applyQuotaSettings()
        }
    }
    
    /// Reset daily usage counters (should be called daily)
    func resetDailyUsage() {
        print("QuotaManager: resetDailyUsage called for \(quotas.count) quotas")
        for (index, quota) in quotas {
            print("QuotaManager: Resetting usage for index: \(index) - was: \(quota.usedToday)")
            quotas[index] = AppQuotaData(
                index: quota.index,
                tokenType: quota.tokenType,
                dailyLimit: quota.dailyLimit,
                usedToday: 0
            )
        }
        saveQuotas()
        
        // Update the last reset date
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        print("QuotaManager: Updated last reset date")
        
        // Reapply settings (should remove all blocks since usage is reset)
        print("QuotaManager: Reapplying settings after reset")
        applyQuotaSettings()
    }
    
    /// Check if we need to reset daily usage (called on app start)
    private func resetDailyUsageIfNeeded() {
        let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date
        let calendar = Calendar.current
        let now = Date()
        
        print("QuotaManager: Checking if daily reset needed...")
        print("QuotaManager: Last reset date: \(lastResetDate?.description ?? "nil")")
        print("QuotaManager: Current date: \(now.description)")
        
        // If no last reset date, or it's a new day, reset usage
        if lastResetDate == nil || !calendar.isDate(lastResetDate!, inSameDayAs: now) {
            print("QuotaManager: Daily reset needed - triggering resetDailyUsage")
            resetDailyUsage()
        } else {
            print("QuotaManager: Daily reset not needed - same day")
        }
    }
    
    /// Save quotas to UserDefaults
    private func saveQuotas() {
        print("QuotaManager: saveQuotas called for \(quotas.count) quotas")
        let quotasList = quotas.values.map { quota in
            return [
                "index": quota.index,
                "tokenType": quota.tokenType,
                "dailyLimit": quota.dailyLimit,
                "usedToday": quota.usedToday
            ] as [String: Any]
        }
        
        let quotasDict = ["quotas": quotasList] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: quotasDict) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("QuotaManager: Successfully saved quotas to UserDefaults")
        } else {
            print("QuotaManager: ERROR - Failed to serialize quotas to JSON")
        }
    }
    
    /// Load quotas from UserDefaults
    private func loadQuotas() {
        print("QuotaManager: loadQuotas called")
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("QuotaManager: No saved quota data found")
            return 
        }
        
        guard let quotasDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("QuotaManager: ERROR - Failed to deserialize quota data")
            return
        }
        
        guard let quotasList = quotasDict["quotas"] as? [[String: Any]] else {
            print("QuotaManager: ERROR - No quotas array found in saved data")
            return
        }
        
        print("QuotaManager: Loading \(quotasList.count) quotas from UserDefaults")
        var loadedQuotas: [Int: AppQuotaData] = [:]
        
        for (_, quotaMap) in quotasList.enumerated() {
            guard let index = quotaMap["index"] as? Int,
                  let dailyLimit = quotaMap["dailyLimit"] as? Int else { 
                print("QuotaManager: ERROR - Invalid quota entry: missing index or dailyLimit")
                continue 
            }
            
            let usedToday = quotaMap["usedToday"] as? Int ?? 0
            let tokenType = quotaMap["tokenType"] as? String ?? "application"
            
            print("QuotaManager: Loaded quota - index: \(index), type: \(tokenType), limit: \(dailyLimit), used: \(usedToday)")
            
            loadedQuotas[index] = AppQuotaData(
                index: index,
                tokenType: tokenType,
                dailyLimit: dailyLimit,
                usedToday: usedToday
            )
        }
        
        quotas = loadedQuotas
        print("QuotaManager: Successfully loaded \(quotas.count) quotas")
    }
    
    /// Start monitoring device activity for usage tracking
    private func startMonitoringActivity() {
        print("QuotaManager: Starting device activity monitoring")
        
        guard !quotas.isEmpty else {
            print("QuotaManager: No quotas to monitor")
            return
        }
        
        let selection = FamilyControlModel.shared.selectionForQuotaConfiguration
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            print("QuotaManager: No apps or categories selected for monitoring")
            return
        }
        
        // Stop any existing monitoring
        deviceActivityCenter.stopMonitoring([quotaActivityName])
        
        // Create schedule for monitoring (full day)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // Create events for each app and category
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        
        // Monitor applications
        let appTokensArray = Array(selection.applicationTokens)
        for (index, _) in appTokensArray.enumerated() {
            let eventName = DeviceActivityEvent.Name("app_\(index)")
            events[eventName] = DeviceActivityEvent(
                applications: Set([appTokensArray[index]]),
                threshold: DateComponents(second: 1) // Track immediately when opened
            )
        }
        
        // Monitor categories
        let categoryTokensArray = Array(selection.categoryTokens)
        for (index, _) in categoryTokensArray.enumerated() {
            let eventName = DeviceActivityEvent.Name("category_\(index)")
            events[eventName] = DeviceActivityEvent(
                categories: Set([categoryTokensArray[index]]),
                threshold: DateComponents(second: 1) // Track immediately when opened
            )
        }
        
        do {
            try deviceActivityCenter.startMonitoring(quotaActivityName, during: schedule, events: events)
            print("QuotaManager: Successfully started monitoring \(events.count) events")
        } catch {
            print("QuotaManager: Failed to start monitoring: \(error)")
        }
    }
    
    /// Stop monitoring device activity
    func stopMonitoringActivity() {
        print("QuotaManager: Stopping device activity monitoring")
        deviceActivityCenter.stopMonitoring([quotaActivityName])
    }
}
