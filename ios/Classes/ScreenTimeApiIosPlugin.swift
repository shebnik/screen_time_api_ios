import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

public class ScreenTimeApiIosPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "screen_time_api_ios", binaryMessenger: registrar.messenger())
        let instance = ScreenTimeApiIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register the platform view factory for app labels
        let factory = AppLabelViewFactory()
        registrar.register(factory, withId: "app_label_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            guard let arguments = call.arguments as? [String: Any] else {
                logError("Configure failed: missing arguments")
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS", message: "Missing configuration arguments",
                        details: nil))
                return
            }

            var configuredItems: [String] = []

            // Configure app group identifier if provided
            if let appGroupId = arguments["appGroupIdentifier"] as? String {
                if ConfigurationManager.shared.validateAppGroupIdentifier(appGroupId) {
                    ConfigurationManager.shared.setAppGroupIdentifier(appGroupId)
                    configuredItems.append("appGroupIdentifier")
                    logSuccess("App group identifier configured: \(appGroupId)")
                } else {
                    logError("Invalid app group identifier format: \(appGroupId)")
                    result(
                        FlutterError(
                            code: "INVALID_APP_GROUP_ID",
                            message: "Invalid app group identifier format",
                            details:
                                "App group identifier must start with 'group.' and contain valid characters"
                        ))
                    return
                }
            }

            // Configure logging if logFilePath is provided
            if let logFilePath = arguments["logFilePath"] as? String {
                Logger.shared.configureLogFile(path: logFilePath)
                configuredItems.append("logging")
                logSuccess("Logging configured: \(logFilePath)")
            }

            result([
                "configured": configuredItems,
                "appGroupIdentifier": ConfigurationManager.shared.appGroupIdentifier,
            ])

        case "configureLogging":
            guard let arguments = call.arguments as? [String: Any],
                let logFilePath = arguments["logFilePath"] as? String
            else {
                logError("Configure logging failed: missing or invalid logFilePath")
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS", message: "Missing logFilePath argument",
                        details: nil))
                return
            }

            Logger.shared.configureLogFile(path: logFilePath)
            logSuccess("Logging configured successfully at: \(logFilePath)")
            result(true)
        case "clearLogs":
            let success = Logger.shared.clearLogs()
            if success {
                logInfo("Log file cleared successfully")
            } else {
                logWarning("Failed to clear log file")
            }
            result(success)
        case "requestAuthorization":
            Task {
                do {
                    logInfo("🔐 Requesting Screen Time authorization")
                    try await FamilyControlModel.shared.authorize()
                    logSuccess("Authorization granted successfully")
                    result(["status": "authorized"])
                } catch {
                    logError("Authorization failed: \(error.localizedDescription)")
                    result(
                        FlutterError(
                            code: "AUTHORIZATION_FAILED",
                            message: "Failed to authorize Screen Time API",
                            details: error.localizedDescription
                        ))
                }
            }
        case "getAuthorizationStatus":
            let status = getAuthorizationStatus()
            logDebug("📋 Authorization status checked: \(status)")
            result(["status": status])
        case "showFamilyActivityPicker":
            Task {
                // Check authorization first
                let authStatus = getAuthorizationStatus()
                if authStatus != "authorized" {
                    logWarning("Family activity picker requested but not authorized: \(authStatus)")
                    result(
                        FlutterError(
                            code: "NOT_AUTHORIZED",
                            message:
                                "Screen Time API not authorized. Call requestAuthorization first.",
                            details: "Current status: \(authStatus)"
                        ))
                    return
                }

                // Extract UI configuration from arguments
                let uiConfigArgs = call.arguments as? [String: Any]
                logInfo("📱 Showing family activity picker")

                await MainActor.run {
                    pendingResult = result
                    showController(with: uiConfigArgs)
                }
            }
        case "selectAppsToDiscourage":
            Task {
                // Check authorization first
                let authStatus = getAuthorizationStatus()
                if authStatus != "authorized" {
                    result(
                        FlutterError(
                            code: "NOT_AUTHORIZED",
                            message:
                                "Screen Time API not authorized. Call requestAuthorization first.",
                            details: "Current status: \(authStatus)"
                        ))
                    return
                }

                // Extract UI configuration from arguments (backward compatibility)
                let uiConfigArgs = call.arguments as? [String: Any]

                await MainActor.run {
                    pendingResult = result
                    showController(with: uiConfigArgs)
                }
            }
        case "getSelectedApps":
            let selectedApps = getSelectedTokens()
            result(selectedApps)
        case "discourageApps":
            Task {
                // Check authorization first
                let authStatus = getAuthorizationStatus()
                if authStatus != "authorized" {
                    result(
                        FlutterError(
                            code: "NOT_AUTHORIZED",
                            message:
                                "Screen Time API not authorized. Call requestAuthorization first.",
                            details: "Current status: \(authStatus)"
                        ))
                    return
                }

                guard let arguments = call.arguments as? [String: Any] else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments provided to discourageApps",
                            details: nil
                        ))
                    return
                }

                do {
                    try await discourageSelection(with: arguments)
                    result(true)
                } catch {
                    result(
                        FlutterError(
                            code: "DISCOURAGE_FAILED",
                            message: "Failed to discourage selection in Screen Time API",
                            details: error.localizedDescription
                        ))
                }
            }
        case "encourageAll":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                logWarning("Encourage all requested but not authorized: \(authStatus)")
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }
            logInfo("🔓 Encouraging all apps - removing restrictions")

            // Clear all selections and encourage all apps
            FamilyControlModel.shared.encourageAll()
            FamilyControlModel.shared.clearAllSelections()

            // Notify all platform views that the selection changed
            NotificationCenter.default.post(
                name: NSNotification.Name("FamilySelectionChanged"), object: nil)

            logSuccess("All apps encouraged and restrictions removed")
            result(nil)
        case "getDiscouragedApps":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            let discouragedApps = FamilyControlModel.shared.getDiscouragedApps()
            result(discouragedApps)
        case "setAdultWebsiteBlocking":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            guard let arguments = call.arguments as? [String: Any],
                let enabled = arguments["enabled"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments provided to setAdultWebsiteBlocking",
                        details: nil
                    ))
                return
            }

            FamilyControlModel.shared.setAdultWebsiteBlocking(enabled: enabled)
            logInfo("🔒 Adult website blocking \(enabled ? "enabled" : "disabled")")
            result(nil)
        case "getAdultWebsiteBlocking":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            let isBlocked = FamilyControlModel.shared.getAdultWebsiteBlocking()
            logInfo("Get adult website blocking called, isBlocked: \(isBlocked)")
            result(isBlocked)
        case "setAppQuotas":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            guard let arguments = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments provided to setAppQuotas",
                        details: nil
                    ))
                return
            }

            Task {
                do {
                    logInfo("Setting app quotas with arguments: \(arguments)")
                    try await FamilyControlModel.shared.setAppQuotas(with: arguments)
                    logSuccess("App quotas set successfully")
                    result(true)
                } catch {
                    logError("Failed to set app quotas: \(error.localizedDescription)")
                    result(
                        FlutterError(
                            code: "QUOTA_SETUP_FAILED",
                            message: "Failed to set app quotas",
                            details: error.localizedDescription
                        ))
                }
            }
        case "getAppQuotas":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            let quotas = FamilyControlModel.shared.getAppQuotas()
            logInfo("Get app quotas completed, returning \(quotas.count) quota(s)")
            logDebug(String(describing: quotas))
            result(quotas)
        case "setWebContentBlocking":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            guard let arguments = call.arguments as? [String: Any],
                let adultContentEnabled = arguments["adultContentEnabled"] as? Bool,
                let blockedDomains = arguments["blockedDomains"] as? [String]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments provided to setWebContentBlocking",
                        details:
                            "Expected: adultContentEnabled (Bool), blockedDomains (List<String>)"
                    ))
                return
            }

            // Validate domain count limits
            if blockedDomains.count > 50 {
                result(
                    FlutterError(
                        code: "TOO_MANY_BLOCKED_DOMAINS",
                        message: "Too many blocked domains. Maximum is 50.",
                        details: "Provided: \(blockedDomains.count)"
                    ))
                return
            }

            Task {
                do {
                    logInfo(
                        "Setting web content blocking - adult content: \(adultContentEnabled), blocked domains: \(blockedDomains.count)"
                    )
                    try await FamilyControlModel.shared.setWebContentBlocking(
                        adultContentEnabled: adultContentEnabled,
                        blockedDomains: blockedDomains
                    )
                    logSuccess("Web content blocking set successfully")
                    result(nil)
                } catch {
                    logError("Failed to set web content blocking: \(error.localizedDescription)")
                    result(
                        FlutterError(
                            code: "WEB_CONTENT_BLOCKING_FAILED",
                            message: "Failed to set web content blocking",
                            details: error.localizedDescription
                        ))
                }
            }
        case "getWebContentBlocking":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(
                    FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                return
            }

            Task {
                do {
                    let webContentConfig = try await FamilyControlModel.shared
                        .getWebContentBlocking()
                    logInfo(
                        "Get web content blocking completed - adult content: \(webContentConfig["adultContentEnabled"] as? Bool ?? false), blocked domains: \((webContentConfig["blockedDomains"] as? [String])?.count ?? 0))"
                    )
                    result(webContentConfig)
                } catch {
                    logError("Failed to get web content blocking: \(error.localizedDescription)")
                    result(
                        FlutterError(
                            code: "WEB_CONTENT_BLOCKING_FETCH_FAILED",
                            message: "Failed to get web content blocking",
                            details: error.localizedDescription
                        ))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @objc func onSelectionSaved() {
        logInfo("Selection saved - processing new family activity selection")

        // Get the newly saved selection
        let selectedTokens = getSelectedTokens()
        logInfo(
            "Saved tokens - apps: \(selectedTokens["applicationTokens"] as? [String] ?? []), categories: \(selectedTokens["categoryTokens"] as? [String] ?? [])"
        )

        dismiss()

        // Notify all platform views that the selection changed
        NotificationCenter.default.post(
            name: NSNotification.Name("FamilySelectionChanged"), object: nil)

        // Return the saved tokens to Flutter
        if let result = pendingResult {
            logSuccess("Returning saved selection result to Flutter")
            result(selectedTokens)
            pendingResult = nil
        }
    }

    @objc func onPressClose() {
        logInfo("Close button pressed - canceling family activity selection")

        // Cancel button was pressed - don't save the temp selection
        FamilyControlModel.shared.resetTempSelection()

        // Get the current saved selection (not temp)
        let selectedTokens = getSelectedTokens()
        logInfo(
            "Returning saved tokens - apps: \(selectedTokens["applicationTokens"] as? [String] ?? []), categories: \(selectedTokens["categoryTokens"] as? [String] ?? [])"
        )

        dismiss()

        // Return the saved tokens to Flutter
        if let result = pendingResult {
            logInfo("Returning selection result to Flutter")
            result(selectedTokens)
            pendingResult = nil
        }
    }

    private func discourageSelection(with arguments: [String: Any]? = nil) async throws {
        let model = FamilyControlModel.shared

        if let arguments = arguments {
            // If arguments provided, decode tokens from Flutter
            let tokenManager = TokenManager()

            var applications: Set<ApplicationToken> = []
            var categories: Set<ActivityCategoryToken> = []
            var webDomains: Set<WebDomainToken> = []

            if let appTokens = arguments["applicationTokens"] as? [String] {
                for tokenString in appTokens {
                    do {
                        let token = try tokenManager.decodeApplicationToken(tokenString)
                        applications.insert(token)
                    } catch {
                        logWarning("Failed to decode application token: \(tokenString)")
                    }
                }
            }

            if let catTokens = arguments["categoryTokens"] as? [String] {
                for tokenString in catTokens {
                    do {
                        let token = try tokenManager.decodeCategoryToken(tokenString)
                        categories.insert(token)
                    } catch {
                        logWarning("Failed to decode category token: \(tokenString)")
                    }
                }
            }

            if let webTokens = arguments["webDomainTokens"] as? [String] {
                for tokenString in webTokens {
                    do {
                        let token = try tokenManager.decodeWebDomainToken(tokenString)
                        webDomains.insert(token)
                    } catch {
                        logWarning("Failed to decode web domain token: \(tokenString)")
                    }
                }
            }

            model.discourage(
                applications: applications, categories: categories, webDomains: webDomains)
        } else {
            // Use current saved selection
            let selection = model.selectionToDiscourage
            model.discourage(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens
            )
        }
    }

    private func getSelectedTokens() -> [String: Any] {
        let selection = FamilyControlModel.shared.selectionToDiscourage
        return encodeSelection(selection)
    }

    private func encodeSelection(_ selection: FamilyActivitySelection) -> [String: Any] {
        let tokenManager = TokenManager()

        var applicationTokens: [String] = []
        for token in selection.applicationTokens {
            do {
                applicationTokens.append(try tokenManager.encodeApplicationToken(token))
            } catch {
                logWarning("Failed to encode application token: \(error)")
            }
        }

        var categoryTokens: [String] = []
        for token in selection.categoryTokens {
            do {
                categoryTokens.append(try tokenManager.encodeCategoryToken(token))
            } catch {
                logWarning("Failed to encode category token: \(error)")
            }
        }

        var webDomainTokens: [String] = []
        for token in selection.webDomainTokens {
            do {
                webDomainTokens.append(try tokenManager.encodeWebDomainToken(token))
            } catch {
                logWarning("Failed to encode web domain token: \(error)")
            }
        }

        var result: [String: Any] = [
            "applicationTokens": applicationTokens,
            "categoryTokens": categoryTokens,
            "webDomainTokens": webDomainTokens,
        ]

        if #available(iOS 15.2, *) {
            result["includeEntireCategory"] = selection.includeEntireCategory
        }

        return result
    }

    private func getAuthorizationStatus() -> String {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .approved:
            return "authorized"
        @unknown default:
            return "unknown"
        }
    }

    func showController(with uiConfigArgs: [String: Any]? = nil) {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let windows = windowScene?.windows
            let controller =
                windows?.filter({ (w) -> Bool in
                    return w.isHidden == false
                }).first?.rootViewController as? FlutterViewController

            // Create UI configuration from arguments
            let uiConfig = UIConfiguration(from: uiConfigArgs)

            // Create ContentView with callbacks and configuration
            let contentView = ContentView(
                onSave: { [weak self] in
                    self?.onSelectionSaved()
                },
                onCancel: { [weak self] in
                    self?.onPressClose()
                },
                uiConfig: uiConfig
            )

            // Display the app selection UI
            let selectAppVC: UIViewController = UIHostingController(rootView: contentView)
            let naviVC = UINavigationController(rootViewController: selectAppVC)
            controller?.present(naviVC, animated: true, completion: nil)
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let windows = windowScene?.windows
            let controller =
                windows?.filter({ (w) -> Bool in
                    return w.isHidden == false
                }).first?.rootViewController as? FlutterViewController
            controller?.dismiss(animated: true, completion: nil)
        }
    }
}
