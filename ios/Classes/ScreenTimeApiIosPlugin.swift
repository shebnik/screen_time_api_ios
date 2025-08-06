import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import SwiftUI

public class ScreenTimeApiIosPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "screen_time_api_ios", binaryMessenger: registrar.messenger())
        let instance = ScreenTimeApiIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Register the platform view factory for app labels
        let factory = AppLabelViewFactory()
        registrar.register(factory, withId: "app_label_view")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            Task {
                do {
                    try await FamilyControlModel.shared.authorize()
                    result(["status": "authorized"])
                } catch {
                    result(FlutterError(
                        code: "AUTHORIZATION_FAILED",
                        message: "Failed to authorize Screen Time API",
                        details: error.localizedDescription
                    ))
                }
            }
        case "getAuthorizationStatus":
            let status = getAuthorizationStatus()
            result(["status": status])
        case "showFamilyActivityPicker":
            Task {
                // Check authorization first
                let authStatus = getAuthorizationStatus()
                if authStatus != "authorized" {
                    result(FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                    return
                }
                
                // Extract UI configuration from arguments
                let uiConfigArgs = call.arguments as? [String: Any]
                
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
                    result(FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
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
                    result(FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                    return
                }
                
                guard let arguments = call.arguments as? [String: Any] else {
                    result(FlutterError(
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
                    result(FlutterError(
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
                result(FlutterError(
                    code: "NOT_AUTHORIZED",
                    message: "Screen Time API not authorized. Call requestAuthorization first.",
                    details: "Current status: \(authStatus)"
                ))
                return
            }
            print("ScreenTimeApiIosPlugin: encourageAll called")
            
            // Clear all selections and encourage all apps
            FamilyControlModel.shared.encourageAll()
            FamilyControlModel.shared.clearAllSelections()
            
            // Notify all platform views that the selection changed
            NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
            
            print("ScreenTimeApiIosPlugin: encourageAll completed")
            result(nil)
        case "getDiscouragedApps":
            // Check authorization first
            let authStatus = getAuthorizationStatus()
            if authStatus != "authorized" {
                result(FlutterError(
                    code: "NOT_AUTHORIZED",
                    message: "Screen Time API not authorized. Call requestAuthorization first.",
                    details: "Current status: \(authStatus)"
                ))
                return
            }
                        
            let discouragedApps = FamilyControlModel.shared.getDiscouragedApps()
            result(discouragedApps)
    default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @objc func onSelectionSaved() {
        print("ScreenTimeApiIosPlugin: onSelectionSaved called")
        
        // Get the newly saved selection
        let selectedTokens = getSelectedTokens()
        print("ScreenTimeApiIosPlugin: Saved tokens - apps: \(selectedTokens["applicationTokens"] as? [String] ?? []), categories: \(selectedTokens["categoryTokens"] as? [String] ?? [])")
        
        dismiss()
        
        // Notify all platform views that the selection changed
        NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
        
        // Return the saved tokens to Flutter
        if let result = pendingResult {
            print("ScreenTimeApiIosPlugin: Returning saved result to Flutter")
            result(selectedTokens)
            pendingResult = nil
        }
    }
    
    @objc func onPressClose() {
        print("ScreenTimeApiIosPlugin: onPressClose called")
        
        // Cancel button was pressed - don't save the temp selection
        FamilyControlModel.shared.resetTempSelection()
        
        // Get the current saved selection (not temp)
        let selectedTokens = getSelectedTokens()
        print("ScreenTimeApiIosPlugin: Returning saved tokens - apps: \(selectedTokens["applicationTokens"] as? [String] ?? []), categories: \(selectedTokens["categoryTokens"] as? [String] ?? [])")
        
        dismiss()
        
        // Return the saved tokens to Flutter
        if let result = pendingResult {
            print("ScreenTimeApiIosPlugin: Returning result to Flutter")
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
                        print("⚠️ Failed to decode application token: \(tokenString)")
                    }
                }
            }
            
            if let catTokens = arguments["categoryTokens"] as? [String] {
                for tokenString in catTokens {
                    do {
                        let token = try tokenManager.decodeCategoryToken(tokenString)
                        categories.insert(token)
                    } catch {
                        print("⚠️ Failed to decode category token: \(tokenString)")
                    }
                }
            }
            
            if let webTokens = arguments["webDomainTokens"] as? [String] {
                for tokenString in webTokens {
                    do {
                        let token = try tokenManager.decodeWebDomainToken(tokenString)
                        webDomains.insert(token)
                    } catch {
                        print("⚠️ Failed to decode web domain token: \(tokenString)")
                    }
                }
            }
            
            model.discourage(applications: applications, categories: categories, webDomains: webDomains)
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
                print("⚠️ Failed to encode application token:", error)
            }
        }

        var categoryTokens: [String] = []
        for token in selection.categoryTokens {
            do {
                categoryTokens.append(try tokenManager.encodeCategoryToken(token))
            } catch {
                print("⚠️ Failed to encode category token:", error)
            }
        }

        var webDomainTokens: [String] = []
        for token in selection.webDomainTokens {
            do {
                webDomainTokens.append(try tokenManager.encodeWebDomainToken(token))
            } catch {
                print("⚠️ Failed to encode web-domain token:", error)
            }
        }

        var result: [String: Any] = [
            "applicationTokens": applicationTokens,
            "categoryTokens": categoryTokens,
            "webDomainTokens": webDomainTokens
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
            let controller = windows?.filter({ (w) -> Bool in
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
    
    func dismiss(){
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let windows = windowScene?.windows
            let controller = windows?.filter({ (w) -> Bool in
                return w.isHidden == false
            }).first?.rootViewController as? FlutterViewController
            controller?.dismiss(animated: true, completion: nil)
        }
    }
}
