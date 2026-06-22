import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.caretoday.app/secure_storage", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "write":
          let args = call.arguments as? [String: Any]
          self.writeToken(args?["value"] as? String ?? "")
          result(nil)
        case "read": result(self.readToken())
        case "delete": self.deleteToken(); result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private let account = "care_today_token"
  private var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.caretoday.app", kSecAttrAccount as String: account] }
  private func writeToken(_ value: String) { deleteToken(); var item = query; item[kSecValueData as String] = value.data(using: .utf8); SecItemAdd(item as CFDictionary, nil) }
  private func readToken() -> String? { var item = query; item[kSecReturnData as String] = true; item[kSecMatchLimit as String] = kSecMatchLimitOne; var result: AnyObject?; guard SecItemCopyMatching(item as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }; return String(data: data, encoding: .utf8) }
  private func deleteToken() { SecItemDelete(query as CFDictionary) }
}
