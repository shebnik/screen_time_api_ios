import SwiftUI
import FamilyControls
import ManagedSettings

enum TokenType {
    case application(ApplicationToken)
    case category(ActivityCategoryToken)
    case webDomain(WebDomainToken)
}

struct AppLabelView: View {
    let tokenType: TokenType
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if #available(iOS 15.2, *) {
                switch tokenType {
                case .application(let token):
                    Label(token)
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                case .category(let token):
                    Label(token)
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(8)
                case .webDomain(let token):
                    Label(token)
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(8)
                }
            } else {
                switch tokenType {
                case .application:
                    Text("Application")
                        .font(.headline)
                        .padding()
                case .category:
                    Text("Category")
                        .font(.headline)
                        .padding()
                case .webDomain:
                    Text("Web Domain")
                        .font(.headline)
                        .padding()
                }
            }
        }
        .padding()
    }
}

struct AppLabelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("AppLabelView Preview")
                .font(.headline)
                .padding()
            Text("Requires valid tokens from Family Controls")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Different background colors:")
                .font(.caption)
            Text("• Gray: Applications")
                .font(.caption)
            Text("• Blue: Categories")
                .font(.caption)
            Text("• Green: Web Domains")
                .font(.caption)
        }
        .padding()
    }
}
