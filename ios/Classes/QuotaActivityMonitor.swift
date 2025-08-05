//
//  QuotaActivityMonitor.swift
//  screen_time_api_ios
//
//  Created for quota usage tracking
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

@available(iOS 15.0, *)
class QuotaActivityMonitor: DeviceActivityMonitor {
    
    override init() {
        super.init()
        print("QuotaActivityMonitor: Initialized")
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("QuotaActivityMonitor: intervalDidStart for activity: \(activity)")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("QuotaActivityMonitor: intervalDidEnd for activity: \(activity)")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("QuotaActivityMonitor: eventDidReachThreshold for event: \(event), activity: \(activity)")
        
        // Track usage when app is opened
        Task {
            await trackAppUsage(for: event, activity: activity)
        }
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("QuotaActivityMonitor: intervalWillStartWarning for activity: \(activity)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("QuotaActivityMonitor: intervalWillEndWarning for activity: \(activity)")
    }
    
    private func trackAppUsage(for event: DeviceActivityEvent.Name, activity: DeviceActivityName) async {
        print("QuotaActivityMonitor: trackAppUsage called for event: \(event)")
        
        // Get the current selection and find which app/category was opened
        let selection = FamilyControlModel.shared.selectionForQuotaConfiguration
        let appTokensArray = Array(selection.applicationTokens)
        let categoryTokensArray = Array(selection.categoryTokens)
        
        // For now, we'll increment usage for all quotas since we can't easily map
        // specific events to specific apps/categories without more complex setup
        // In a real implementation, you'd want to create specific events for each app/category
        
        print("QuotaActivityMonitor: Available apps: \(appTokensArray.count), categories: \(categoryTokensArray.count)")
        
        // This is a simplified approach - increment usage for the first quota
        // In practice, you'd need to map the event to the specific app/category
        if !QuotaManager.shared.quotas.isEmpty {
            let firstQuotaIndex = QuotaManager.shared.quotas.keys.first!
            print("QuotaActivityMonitor: Tracking usage for index: \(firstQuotaIndex)")
            QuotaManager.shared.trackAppUsage(index: firstQuotaIndex)
        }
    }
}
