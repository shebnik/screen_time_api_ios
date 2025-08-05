import UIKit
import SwiftUI
import FamilyControls
import Flutter
import Combine
import ManagedSettings

class AppLabelViewController: UIViewController {
    private var hostingController: UIHostingController<AnyView>?
    private let tokenIndex: Int
    private let tokenType: String
    
    init(tokenIndex: Int, tokenType: String) {
        self.tokenIndex = tokenIndex
        self.tokenType = tokenType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppLabelView()
    }
    
    private func setupAppLabelView() {
        // Get the current selection and get the token by index and type
        let selection = FamilyControlModel.shared.selectionToDiscourage
        
        print("AppLabelViewFactory: tokenType=\(tokenType), tokenIndex=\(tokenIndex)")
        print("AppLabelViewFactory: available app tokens=\(selection.applicationTokens.count)")
        print("AppLabelViewFactory: available category tokens=\(selection.categoryTokens.count)")
        print("AppLabelViewFactory: available webDomain tokens=\(selection.webDomainTokens.count)")
        
        var tokenTypeResult: TokenType?
        
        switch tokenType {
        case "application":
            let tokens = Array(selection.applicationTokens)
            print("AppLabelViewFactory: Looking for application token at index \(tokenIndex) of \(tokens.count)")
            if tokenIndex < tokens.count {
                tokenTypeResult = .application(tokens[tokenIndex])
                print("AppLabelViewFactory: Found application token!")
            }
        case "category":
            let tokens = Array(selection.categoryTokens)
            print("AppLabelViewFactory: Looking for category token at index \(tokenIndex) of \(tokens.count)")
            if tokenIndex < tokens.count {
                tokenTypeResult = .category(tokens[tokenIndex])
                print("AppLabelViewFactory: Found category token!")
            }
        case "webDomain":
            let tokens = Array(selection.webDomainTokens)
            print("AppLabelViewFactory: Looking for webDomain token at index \(tokenIndex) of \(tokens.count)")
            if tokenIndex < tokens.count {
                tokenTypeResult = .webDomain(tokens[tokenIndex])
                print("AppLabelViewFactory: Found webDomain token!")
            }
        default:
            print("AppLabelViewFactory: Unknown token type: \(tokenType)")
        }
        
        if let tokenTypeResult = tokenTypeResult {
            let appLabelView = AppLabelView(tokenType: tokenTypeResult)
            hostingController = UIHostingController(rootView: AnyView(appLabelView))
        } else {
            // If token not found, show an error message
            let errorView = VStack {
                Text("Token not available")
                    .foregroundColor(.red)
                Text("Type: \(tokenType)")
                    .font(.caption)
                Text("Index: \(tokenIndex)")
                    .font(.caption)
                Text("Available: app=\(selection.applicationTokens.count), cat=\(selection.categoryTokens.count), web=\(selection.webDomainTokens.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            hostingController = UIHostingController(rootView: AnyView(errorView))
        }
        
        setupHostingController()
    }
    
    private func setupHostingController() {
        guard let newHostingController = hostingController else { return }
        
        // Remove any existing hosting controller first
        if let existingController = children.first(where: { $0 is UIHostingController<AnyView> }) {
            existingController.willMove(toParent: nil)
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
        }
        
        addChild(newHostingController)
        view.addSubview(newHostingController.view)
        newHostingController.didMove(toParent: self)
        
        // Set up constraints
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            newHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set transparent background
        view.backgroundColor = UIColor.clear
        newHostingController.view.backgroundColor = UIColor.clear
    }
}

class AppLabelViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return AppLabelPlatformView(frame: frame, viewId: viewId, args: args)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class AppLabelPlatformView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private let _controller: AppLabelViewController
    
    init(frame: CGRect, viewId: Int64, args: Any?) {
        // Extract token index and type from arguments
        var tokenIndex = 0
        var tokenType = "application"
        
        print("AppLabelViewFactory init: args = \(String(describing: args))")
        
        if let arguments = args as? [String: Any] {
            print("AppLabelViewFactory init: arguments = \(arguments)")
            if let index = arguments["tokenIndex"] as? Int {
                tokenIndex = index
                print("AppLabelViewFactory init: extracted tokenIndex = \(tokenIndex)")
            }
            if let type = arguments["tokenType"] as? String {
                tokenType = type
                print("AppLabelViewFactory init: extracted tokenType = \(tokenType)")
            }
        } else {
            print("AppLabelViewFactory init: arguments is not a dictionary")
        }
        
        print("AppLabelViewFactory init: final values - tokenIndex=\(tokenIndex), tokenType=\(tokenType)")
        
        _controller = AppLabelViewController(tokenIndex: tokenIndex, tokenType: tokenType)
        _view = _controller.view
        super.init()
        
        _view.frame = frame
    }
    
    func view() -> UIView {
        return _view
    }
}
