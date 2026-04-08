# Chinese Language Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Simplified Chinese localization with a user-selectable language toggle in Settings.

**Architecture:** Xcode String Catalogs (.xcstrings) for translations, @AppStorage for language preference, String(localized:) for automatic locale resolution.

**Tech Stack:** Swift, SwiftUI, Xcode String Catalogs, UserDefaults

---

### Task 1: Create String Catalog File

**Files:**
- Create: `ZaiUsageMenuBar/Resources/Localizable.xcstrings`

- [ ] **Step 1: Create Localizable.xcstrings with all translations**

Create the string catalog file with English base and Chinese (Simplified) translations. The .xcstrings format is a JSON-like structure:

```json
{
  "sourceLanguage": "en",
  "strings": {
    "app_title": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Zai Usage"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "智谱coding plan 用量查询"
          }
        }
      }
    },
    "settings": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Settings"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "设置"
          }
        }
      }
    },
    "quit": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Quit"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "退出"
          }
        }
      }
    },
    "retry": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Retry"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "重试"
          }
        }
      }
    },
    "quota": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Quota"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "配额"
          }
        }
      }
    },
    "token_label": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Token (5h)"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "Token (5小时)"
          }
        }
      }
    },
    "mcp_label": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "MCP (1m)"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "MCP (1个月)"
          }
        }
      }
    },
    "resets_prefix": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "resets"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "重置"
          }
        }
      }
    },
    "model_usage": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Model Usage"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "模型用量"
          }
        }
      }
    },
    "tools": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Tools"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "工具调用"
          }
        }
      }
    },
    "calls_suffix": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "calls"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "次调用"
          }
        }
      }
    },
    "api_config": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "API Configuration"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "API 配置"
          }
        }
      }
    },
    "base_url": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Base URL"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "基础 URL"
          }
        }
      }
    },
    "auth_token": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Auth Token"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "认证令牌"
          }
        }
      }
    },
    "auth_token_placeholder": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Your authentication token"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "你的认证令牌"
          }
        }
      }
    },
    "done": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Done"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "完成"
          }
        }
      }
    },
    "language": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Language"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "语言"
          }
        }
      }
    },
    "system_default": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "System Default"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "跟随系统"
          }
        }
      }
    }
  },
  "version": "1.0"
}
```

- [ ] **Step 2: Verify file was created**

Run: `ls ZaiUsageMenuBar/Resources/Localizable.xcstrings`
Expected: File exists and is readable

---

### Task 2: Update MenuBarContentView with Localized Strings

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

- [ ] **Step 1: Replace all hardcoded strings with localized keys**

The complete updated file content:

```swift
import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var viewModel = UsageViewModel()
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(lastUpdated: viewModel.lastUpdated, isLoading: viewModel.isLoading, showSettings: $showSettings)
            
            ScrollView {
                VStack(spacing: 8) {
                    if let error = viewModel.error {
                        ErrorView(message: error, retryAction: viewModel.refresh)
                    }
                    
                    if let quotaLimits = viewModel.quotaLimits {
                        QuotaLimitsView(quotaData: quotaLimits)
                    }
                    
                    if let modelUsage = viewModel.modelUsage {
                        ModelUsageView(modelData: modelUsage)
                    }
                    
                    if let toolUsage = viewModel.toolUsage {
                        ToolUsageView(toolData: toolUsage)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(4)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
        .frame(width: 300)
        .onAppear {
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshUsage)) { _ in
            viewModel.refresh()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct HeaderView: View {
    let lastUpdated: Date?
    let isLoading: Bool
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text("app_title")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }
            
            if let lastUpdated = lastUpdated {
                Text(lastUpdated, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("settings")
            
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("quit")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(message)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
            Spacer()
            Button("retry", action: retryAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(6)
        .background(Color.red.opacity(0.1))
        .cornerRadius(6)
    }
}

struct QuotaLimitsView: View {
    let quotaData: QuotaLimitData
    
    var tokenLimit: QuotaLimit? {
        quotaData.limits?.first { $0.type == "TOKENS_LIMIT" }
    }
    
    var timeLimit: QuotaLimit? {
        quotaData.limits?.first { $0.type == "TIME_LIMIT" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("quota")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let level = quotaData.level {
                    Text(level.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(3)
                }
            }
            
            if let tokenLimit = tokenLimit {
                QuotaLimitRow(limit: tokenLimit, label: "token_label")
            }
            
            if let timeLimit = timeLimit {
                QuotaLimitRow(limit: timeLimit, label: "mcp_label")
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct QuotaLimitRow: View {
    let limit: QuotaLimit
    let label: String
    
    var resetDate: Date? {
        guard let nextResetTime = limit.nextResetTime else { return nil }
        return Date(timeIntervalSince1970: nextResetTime / 1000)
    }
    
    var progressColor: Color {
        guard let percentage = limit.percentage else { return .green }
        if percentage >= 90 { return .red }
        else if percentage >= 70 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let current = limit.currentValue, let usage = limit.usage {
                    Text(String(format: "%.0f/%.0f", current, usage))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let percentage = limit.percentage {
                    Text(String(format: "%.0f%%", percentage))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                }
            }
            
            if let percentage = limit.percentage {
                ProgressView(value: min(percentage, 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 3)
            }
            
            if let resetDate = resetDate {
                HStack {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("resets_prefix \(resetDate, style: .relative)")
                        .font(.caption2)
                }
                .foregroundColor(Color.secondary)
            }
        }
    }
}

struct ModelUsageView: View {
    let modelData: ModelUsageData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("model_usage")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let totalUsage = modelData.totalUsage, let tokens = totalUsage.totalTokensUsage {
                    Text(formatTokens(tokens))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let totalUsage = modelData.totalUsage, let calls = totalUsage.totalModelCallCount {
                HStack(spacing: 12) {
                    Label("\(calls)", systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

struct ToolUsageView: View {
    let toolData: ToolUsageData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("tools")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let totalUsage = toolData.totalUsage, let searchCount = totalUsage.totalSearchMcpCount {
                    Text("\(searchCount) calls_suffix")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let toolDetails = toolData.totalUsage?.toolDetails, !toolDetails.isEmpty {
                ForEach(Array(toolDetails.enumerated()), id: \.offset) { _, detail in
                    HStack {
                        Text(detail.modelName ?? "")
                            .font(.caption2)
                        Spacer()
                        Text("\(detail.totalUsageCount ?? 0)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd ZaiUsageMenuBar && swift build 2>&1 | head -20`
Expected: No errors related to the modified file

---

### Task 3: Add Language Picker to SettingsView

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/SettingsView.swift`

- [ ] **Step 1: Update SettingsView with language picker**

The complete updated file content:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropicAuthToken") private var authToken: String = ""
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "system"
    
    var body: some View {
        VStack(spacing: 20) {
            Form {
                Section("language") {
                    Picker("language", selection: $preferredLanguage) {
                        Text("system_default").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                }
                
                Section("api_config") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("base_url")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("https://open.bigmodel.cn/api/anthropic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("auth_token")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        SecureField("auth_token_placeholder", text: $authToken)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            HStack {
                Spacer()
                
                Button("done") {
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
```

Key changes:
- Added `@AppStorage("preferredLanguage")` property with default "system"
- Added new "Language" section with Picker
- Updated form height from 160 to 200 to accommodate new picker
- Replaced all hardcoded strings with localization keys

- [ ] **Step 2: Verify file compiles**

Run: `cd ZaiUsageMenuBar && swift build 2>&1 | head -20`
Expected: No errors related to the modified file

---

### Task 4: Apply Language Preference on App Launch

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/ZaiUsageMenuBarApp.swift`

- [ ] **Step 1: Add language initialization logic**

The complete updated file content:

```swift
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
        
        if let locale = Locale(identifier: preferredLanguage) as? NSLocale {
            UserDefaults.standard.set([preferredLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
}
```

Key changes:
- Added `@AppStorage("preferredLanguage")` property
- Added `init()` to apply language preference before UI loads
- Added `applyLanguagePreference()` method that sets AppleLanguages user default

- [ ] **Step 2: Verify file compiles**

Run: `cd ZaiUsageMenuBar && swift build 2>&1 | head -20`
Expected: No errors related to the modified file

---

### Task 5: Build and Verify

**Files:**
- All modified files from previous tasks

- [ ] **Step 1: Full build verification**

Run: `cd ZaiUsageMenuBar && swift build`
Expected: BUILD SUCCEEDED with no errors

- [ ] **Step 2: Verify all localization keys are present**

Run: `grep -r "Text(\"" ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/ | grep -v "systemImage" | grep -v "format"`
Expected: All Text() calls use localization keys from Localizable.xcstrings

- [ ] **Step 3: Verify no hardcoded English strings remain in UI**

Run: `grep -E "Text\(\"(Zai Usage|Settings|Quit|Retry|Quota|Model Usage|Tools|Done)\"\)" ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/`
Expected: No matches (all strings should be localized)
