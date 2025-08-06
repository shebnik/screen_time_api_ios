//
//  ConfigurationManager.swift
//  screen_time_api_ios
//
//  Created by Assistant on 8/7/25.
//

import Foundation

/// Manages configuration settings that can be set from Flutter
class ConfigurationManager {
    static let shared = ConfigurationManager()

    private var _appGroupIdentifier: String

    private init() {
        // Initialize from UserDefaults if available, otherwise use default
        _appGroupIdentifier =
            UserDefaults.standard.string(forKey: "AppGroupIdentifierConfig")
            ?? "group.com.example.screenTimeApiIosExample"
    }

    /// Get the current app group identifier
    var appGroupIdentifier: String {
        return _appGroupIdentifier
    }

    /// Set the app group identifier from Flutter
    func setAppGroupIdentifier(_ identifier: String) {
        print("📱 Setting app group identifier to: \(identifier)")
        _appGroupIdentifier = identifier

        // Save to UserDefaults so extension can access it
        UserDefaults.standard.set(identifier, forKey: "AppGroupIdentifierConfig")
        UserDefaults.standard.synchronize()

        // Notify existing components that the configuration has changed
        NotificationCenter.default.post(
            name: NSNotification.Name("AppGroupIdentifierChanged"),
            object: identifier
        )

        print("✅ App group identifier configured successfully")
    }

    /// Validate the app group identifier format
    func validateAppGroupIdentifier(_ identifier: String) -> Bool {
        // App group identifiers should start with "group." and contain valid characters
        let pattern = "^group\\.[a-zA-Z0-9.-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: identifier.utf16.count)
        return regex?.firstMatch(in: identifier, options: [], range: range) != nil
    }

    /// Get configuration info for debugging
    func getConfigurationInfo() -> [String: Any] {
        return [
            "appGroupIdentifier": appGroupIdentifier,
            "isValidAppGroupId": validateAppGroupIdentifier(appGroupIdentifier),
        ]
    }
}
