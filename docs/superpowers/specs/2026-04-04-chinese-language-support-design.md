# Chinese Language Support Design

## Overview

Add Simplified Chinese localization to the ZaiUsageMenuBar app using Xcode String Catalogs, with a user-selectable language toggle in Settings.

## Architecture

### String Catalog
- Create `Resources/Localizable.xcstrings` with English base and Chinese (Simplified) translation
- All UI text uses `String(localized:)` for automatic locale resolution

### Language Preference
- Stored in `@AppStorage("preferredLanguage")`
- Values: `"system"`, `"en"`, `"zh-Hans"`
- Default: `"system"`

### Settings UI
- New "Language" section above "API Configuration"
- Picker with: System Default, English, 简体中文

## Localized Strings

| Key | English | Chinese (Simplified) |
|-----|---------|---------------------|
| app_title | Zai Usage | 智谱coding plan 用量查询 |
| settings | Settings | 设置 |
| quit | Quit | 退出 |
| retry | Retry | 重试 |
| quota | Quota | 配额 |
| token_label | Token (5h) | Token (5小时) |
| mcp_label | MCP (1m) | MCP (1个月) |
| resets | resets | 重置 |
| model_usage | Model Usage | 模型用量 |
| tools | Tools | 工具调用 |
| calls | calls | 次调用 |
| api_config | API Configuration | API 配置 |
| base_url | Base URL | 基础 URL |
| auth_token | Auth Token | 认证令牌 |
| auth_token_placeholder | Your authentication token | 你的认证令牌 |
| done | Done | 完成 |
| language | Language | 语言 |
| system_default | System Default | 跟随系统 |

## File Changes

1. **Resources/Localizable.xcstrings** — New file, all string translations
2. **MenuBarContentView.swift** — Replace hardcoded strings with `String(localized:)`
3. **SettingsView.swift** — Add language picker section
4. **ZaiUsageMenuBarApp.swift** — Apply preferred language on launch

## Data Flow

```
Settings → @AppStorage("preferredLanguage") → UserDefaults
    ↓
App reads on launch and settings change
    ↓
String(localized:) uses correct locale automatically
```
