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
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @objc func onPressClose(){
        // Get the selected tokens before dismissing
        let selectedTokens = getSelectedTokens()
        dismiss()
        
        // Return the selected tokens to Flutter
        if let result = pendingResult {
            result(selectedTokens)
            pendingResult = nil
        }
    }
    
    private func getSelectedTokens() -> [String] {
        let selection = FamilyControlModel.shared.selectionToDiscourage
        let applicationTokens = selection.applicationTokens
        let categoryTokens = selection.categoryTokens
        
        var tokens: [String] = []
        
        // Convert application tokens to strings
        for token in applicationTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            tokens.append(data.base64EncodedString())
        }
        
        // Convert category tokens to strings
        for token in categoryTokens {
            let data = withUnsafeBytes(of: token) { Data($0) }
            tokens.append(data.base64EncodedString())
        }
        
        return tokens
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
