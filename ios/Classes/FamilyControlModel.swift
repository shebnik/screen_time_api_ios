//
//  FamilyControlModel.swift
//  screen_time_api_ios
//
//  Created by Kei Fujikawa on 2023/10/11.
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class FamilyControlModel: ObservableObject {
    static let shared = FamilyControlModel()

    private init() {
        selectionToDiscourage = savedSelection() ?? FamilyActivitySelection()
        tempSelection = selectionToDiscourage
    }

    private let store = ManagedSettingsStore()
    private let userDefaultsKey = "ScreenTimeSelection"
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    @Published var selectionToDiscourage = FamilyActivitySelection()
    @Published var tempSelection = FamilyActivitySelection() // For picker interaction without saving

    func authorize() async throws {
        if #available(iOS 16.0, *) {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } else {
            AuthorizationCenter.shared.requestAuthorization(completionHandler: { _ in })
        }
    }
    
    func discourage(applications: Set<ApplicationToken>, categories: Set<ActivityCategoryToken>, webDomains: Set<WebDomainToken>) {
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
                print("⚠️ Failed to encode application token:", error)
            }
        }
        
        var categoryTokens: [String] = []
        for token in allCategories {
            do {
                categoryTokens.append(try tokenManager.encodeCategoryToken(token))
            } catch {
                print("⚠️ Failed to encode category token:", error)
            }
        }
        
        var webDomainTokens: [String] = []
        for token in webDomains {
            do {
                webDomainTokens.append(try tokenManager.encodeWebDomainToken(token))
            } catch {
                print("⚠️ Failed to encode web-domain token:", error)
            }
        }
        
        return [
            "applicationTokens": applicationTokens,
            "categoryTokens": categoryTokens,
            "webDomainTokens": webDomainTokens
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
        print("Selection Reset")
    }
    
    func clearTempSelection() {
        tempSelection = FamilyActivitySelection()
        print("Selection Cleared")
    }
    
    func clearAllSelections() {
        tempSelection = FamilyActivitySelection()
        selectionToDiscourage = FamilyActivitySelection()
        saveSelection(selection: selectionToDiscourage)
        print("All Selections Cleared")
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
}
