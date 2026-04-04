import SwiftUI

@main
struct ZaiUsageMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "system"
    
    init() {
        applyLanguagePreference()
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
    
    private func applyLanguagePreference() {
        guard preferredLanguage != "system" else { return }
        
        let languageCode = preferredLanguage == "zh-Hans" ? "zh-Hans" : "en"
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}
