import SwiftUI

@main
struct ZaiUsageMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        applyLanguagePreference()
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
    
    private func applyLanguagePreference() {
        let preferredLanguage = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "system"
        guard preferredLanguage != "system" else { return }
        
        let languageCode = preferredLanguage == "zh-Hans" ? "zh-Hans" : "en"
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
    }
}
