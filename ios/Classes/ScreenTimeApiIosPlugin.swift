import Flutter
import UIKit
import FamilyControls
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
                    pendingResult = result
                    showController()
                }
            }
        case "getDiscouragedApps":
            let discouragedApps = getSelectedTokens()
            result(discouragedApps)
        case "encourageAll":
            // Encourage all apps
            FamilyControlModel.shared.encourageAll()
            FamilyControlModel.shared.selectionToDiscourage = FamilyActivitySelection()
            FamilyControlModel.shared.saveSelection(selection: FamilyActivitySelection())
            
            // Notify all platform views that the selection changed
            NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
            
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @objc func onPressClose(){
        // Get the selected tokens before dismissing
        let selectedTokens = getSelectedTokens()
        dismiss()
        
        // Notify all platform views that the selection changed
        NotificationCenter.default.post(name: NSNotification.Name("FamilySelectionChanged"), object: nil)
        
        // Return the selected tokens to Flutter
        if let result = pendingResult {
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
