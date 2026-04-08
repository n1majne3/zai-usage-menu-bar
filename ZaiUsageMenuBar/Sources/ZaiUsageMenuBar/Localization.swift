import Foundation

enum L10n {
    static var preferredLanguage: String {
        UserDefaults.standard.string(forKey: "preferredLanguage") ?? "system"
    }

    private static let translations: [String: [String: String]] = [
        "app_title": [
            "en": "Zai Usage",
            "zh": "智谱coding plan 用量查询",
        ],
        "settings": [
            "en": "Settings",
            "zh": "设置",
        ],
        "quit": [
            "en": "Quit",
            "zh": "退出",
        ],
        "retry": [
            "en": "Retry",
            "zh": "重试",
        ],
        "refresh": [
            "en": "Refresh",
            "zh": "刷新",
        ],
        "quota": [
            "en": "Quota",
            "zh": "配额",
        ],
        "token_label": [
            "en": "Token (5h)",
            "zh": "Token (5小时)",
        ],
        "weekly_token_label": [
            "en": "Token (1w)",
            "zh": "Token (1周)",
        ],
        "mcp_label": [
            "en": "MCP (1m)",
            "zh": "MCP (1个月)",
        ],
        "resets_prefix": [
            "en": "resets",
            "zh": "重置",
        ],
        "model_usage": [
            "en": "Model Usage",
            "zh": "模型用量",
        ],
        "tools": [
            "en": "Tools",
            "zh": "工具调用",
        ],
        "add_account": [
            "en": "Add Account",
            "zh": "添加账号",
        ],
        "enabled": [
            "en": "Enabled",
            "zh": "启用",
        ],
        "delete": [
            "en": "Delete",
            "zh": "删除",
        ],
        "cancel": [
            "en": "Cancel",
            "zh": "取消",
        ],
        "delete_account_title": [
            "en": "Delete Account?",
            "zh": "删除账号？",
        ],
        "delete_account_message": [
            "en": "Remove %1$@ from this app? Its saved token will also be removed.",
            "zh": "要从应用中移除 %1$@ 吗？已保存的令牌也会被删除。",
        ],
        "default_account_name": [
            "en": "Default Account",
            "zh": "默认账号",
        ],
        "unnamed_account": [
            "en": "Unnamed Account",
            "zh": "未命名账号",
        ],
        "no_accounts_added": [
            "en": "Add at least one account.",
            "zh": "请至少添加一个账号。",
        ],
        "account_name_placeholder": [
            "en": "Account name",
            "zh": "账号名称",
        ],
        "account_name_required": [
            "en": "Enabled accounts need a name.",
            "zh": "启用的账号必须填写名称。",
        ],
        "auth_token_required": [
            "en": "Enabled accounts need an auth token.",
            "zh": "启用的账号必须填写认证令牌。",
        ],
        "no_accounts_configured": [
            "en": "No enabled account configured. Open settings to add one.",
            "zh": "未配置启用账号，请在设置中添加。",
        ],
        "all_accounts_failed": [
            "en": "All account requests failed. Check account tokens.",
            "zh": "所有账号请求失败，请检查账号令牌。",
        ],
        "calls_suffix": [
            "en": "calls",
            "zh": "次调用",
        ],
        "api_config": [
            "en": "API Configuration",
            "zh": "API 配置",
        ],
        "base_url": [
            "en": "Base URL",
            "zh": "基础 URL",
        ],
        "auth_token": [
            "en": "Auth Token",
            "zh": "认证令牌",
        ],
        "auth_token_placeholder": [
            "en": "Your authentication token",
            "zh": "你的认证令牌",
        ],
        "done": [
            "en": "Done",
            "zh": "完成",
        ],
        "language": [
            "en": "Language",
            "zh": "语言",
        ],
        "system_default": [
            "en": "System Default",
            "zh": "跟随系统",
        ],
        "hourly_tokens": [
            "en": "Hourly Tokens",
            "zh": "每小时 Token",
        ],
        "no_data": [
            "en": "No data",
            "zh": "暂无数据",
        ],
        "today": [
            "en": "Today",
            "zh": "今天",
        ],
    ]

    static func localized(_ key: String) -> String {
        let lang =
            preferredLanguage == "system"
            ? (Locale.current.language.languageCode?.identifier ?? "en") : preferredLanguage

        let langKey = lang.hasPrefix("zh") ? "zh" : "en"
        return translations[key]?[langKey] ?? translations[key]?["en"] ?? key
    }
}
