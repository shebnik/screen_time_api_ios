import Flutter
import UIKit
import FamilyControls
import SwiftUI

public class ScreenTimeApiIosPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?
    private var isQuotaConfigurationMode: Bool = false
    
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
                
                await MainActor.run {
                    isQuotaConfigurationMode = false
                    pendingResult = result
                    showController()
                }
            }
        case "selectAppsForQuotaConfiguration":
            print("ScreenTimeApiIosPlugin: selectAppsForQuotaConfiguration called")
            Task {
                // Check authorization first
                let authStatus = getAuthorizationStatus()
                if authStatus != "authorized" {
                    print("ScreenTimeApiIosPlugin: ERROR - Not authorized: \(authStatus)")
                    result(FlutterError(
                        code: "NOT_AUTHORIZED",
                        message: "Screen Time API not authorized. Call requestAuthorization first.",
                        details: "Current status: \(authStatus)"
                    ))
                    return
                }
                
                await MainActor.run {
                    isQuotaConfigurationMode = true
                    pendingResult = result
                    print("ScreenTimeApiIosPlugin: Showing quota configuration controller")
                    showQuotaConfigurationController()
                }
            }
        case "setAppQuotas":
            print("ScreenTimeApiIosPlugin: setAppQuotas called")
            guard let quotasDict = call.arguments as? [String: Any] else {
                print("ScreenTimeApiIosPlugin: ERROR - Invalid quota arguments: \(String(describing: call.arguments))")
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid quota arguments", details: nil))
                return
            }
            print("ScreenTimeApiIosPlugin: Setting quotas with: \(quotasDict)")
            QuotaManager.shared.setQuotas(quotasDict)
            result(nil)
        case "getAppQuotas":
            print("ScreenTimeApiIosPlugin: getAppQuotas called")
            let quotas = QuotaManager.shared.getQuotas()
            print("ScreenTimeApiIosPlugin: Returning quotas: \(quotas)")
            result(quotas)
        case "applyQuotaSettings":
            print("ScreenTimeApiIosPlugin: applyQuotaSettings called")
            QuotaManager.shared.applyQuotaSettings()
            print("ScreenTimeApiIosPlugin: applyQuotaSettings completed")
            result(nil)
        case "simulateAppUsage":
            guard let arguments = call.arguments as? [String: Any],
                  let index = arguments["index"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing index parameter", details: nil))
                return
            }
            print("ScreenTimeApiIosPlugin: simulateAppUsage called for index: \(index)")
            QuotaManager.shared.trackAppUsage(index: index)
            print("ScreenTimeApiIosPlugin: simulateAppUsage completed")
            result(nil)
        case "getDiscouragedApps":
            let discouragedApps = getSelectedTokens()
            result(discouragedApps)
        case "encourageAll":
            print("ScreenTimeApiIosPlugin: encourageAll called")
            // Encourage all apps and clear quotas
            FamilyControlModel.shared.encourageAll()
            FamilyControlModel.shared.selectionToDiscourage = FamilyActivitySelection()
            FamilyControlModel.shared.saveSelection(selection: FamilyActivitySelection())
            
            // Also clear quota-based restrictions
            QuotaManager.shared.removeAllRestrictions()
            
            // Notify all platform views that the selection changed
            NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
            
            print("ScreenTimeApiIosPlugin: encourageAll completed")
            result(nil)
    default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @objc func onPressClose(){
        print("ScreenTimeApiIosPlugin: onPressClose called, isQuotaConfigurationMode: \(isQuotaConfigurationMode)")
        // Get the selected tokens before dismissing
        let selectedTokens = isQuotaConfigurationMode ? getQuotaConfigurationTokens() : getSelectedTokens()
        print("ScreenTimeApiIosPlugin: Selected tokens count - apps: \(selectedTokens["applicationTokens"] as? [String] ?? []), categories: \(selectedTokens["categoryTokens"] as? [String] ?? [])")
        dismiss()
        
        // Notify all platform views that the selection changed
        NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
        
        // Return the selected tokens to Flutter
        if let result = pendingResult {
            print("ScreenTimeApiIosPlugin: Returning result to Flutter")
            result(selectedTokens)
            pendingResult = nil
        }
    }
    
    private func getSelectedTokens() -> [String: Any] {
        let selection = FamilyControlModel.shared.selectionToDiscourage
        
        var result: [String: Any] = [
            "applicationTokens": [],
            "categoryTokens": [],
            "webDomainTokens": []
        ]
        
        // Convert application tokens to strings
        var applicationTokens: [String] = []
        for token in selection.applicationTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            applicationTokens.append(data.base64EncodedString())
        }
        result["applicationTokens"] = applicationTokens
        
        // Convert category tokens to strings
        var categoryTokens: [String] = []
        for token in selection.categoryTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            categoryTokens.append(data.base64EncodedString())
        }
        result["categoryTokens"] = categoryTokens
        
        // Convert web domain tokens to strings
        var webDomainTokens: [String] = []
        for token in selection.webDomainTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            webDomainTokens.append(data.base64EncodedString())
        }
        result["webDomainTokens"] = webDomainTokens
        
        // Add includeEntireCategory if available (iOS 15.2+)
        if #available(iOS 15.2, *) {
            result["includeEntireCategory"] = selection.includeEntireCategory
        }
        
        return result
    }
    
    private func getQuotaConfigurationTokens() -> [String: Any] {
        let selection = FamilyControlModel.shared.selectionForQuotaConfiguration
        
        var result: [String: Any] = [
            "applicationTokens": [],
            "categoryTokens": [],
            "webDomainTokens": []
        ]
        
        // Convert application tokens to strings
        var applicationTokens: [String] = []
        for token in selection.applicationTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            applicationTokens.append(data.base64EncodedString())
        }
        result["applicationTokens"] = applicationTokens
        
        // Convert category tokens to strings
        var categoryTokens: [String] = []
        for token in selection.categoryTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            categoryTokens.append(data.base64EncodedString())
        }
        result["categoryTokens"] = categoryTokens
        
        // Convert web domain tokens to strings
        var webDomainTokens: [String] = []
        for token in selection.webDomainTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            webDomainTokens.append(data.base64EncodedString())
        }
        result["webDomainTokens"] = webDomainTokens
        
        // Add includeEntireCategory if available (iOS 15.2+)
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
    
    func showController() {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let windows = windowScene?.windows
            let controller = windows?.filter({ (w) -> Bool in
                return w.isHidden == false
            }).first?.rootViewController as? FlutterViewController
            
            // Display the app selection UI
            let selectAppVC: UIViewController = UIHostingController(rootView: ContentView())
            selectAppVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(self.onPressClose)
            )
            let naviVC = UINavigationController(rootViewController: selectAppVC)
            controller?.present(naviVC, animated: true, completion: nil)
        }
    }
    
    func showQuotaConfigurationController() {
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let windows = windowScene?.windows
            let controller = windows?.filter({ (w) -> Bool in
                return w.isHidden == false
            }).first?.rootViewController as? FlutterViewController
            
            // Display the quota configuration UI
            let selectAppVC: UIViewController = UIHostingController(rootView: QuotaConfigurationView())
            selectAppVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(self.onPressClose)
            )
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
