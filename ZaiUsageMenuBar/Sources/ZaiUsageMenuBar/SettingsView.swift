import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "system"
    @State private var accounts: [AccountConfig] = []
    @State private var errorMessage: String?
    @State private var pendingDeleteAccount: AccountConfig?
    
    var body: some View {
        VStack(spacing: 12) {
            Form {
                Section(L10n.localized("language")) {
                    Picker(L10n.localized("language"), selection: $preferredLanguage) {
                        Text(L10n.localized("system_default")).tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                }
                
                Section(L10n.localized("api_config")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.localized("base_url"))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("https://open.bigmodel.cn/api/anthropic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.localized("accounts"))
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Button(L10n.localized("add_account")) {
                                accounts.append(AccountConfig.newDefault())
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        if accounts.isEmpty {
                            Text(L10n.localized("no_accounts_added"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach($accounts) { $account in
                                AccountEditorRow(account: $account) {
                                    pendingDeleteAccount = account
                                }
                            }
                        }
                    }
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Spacer()
                
                Button(L10n.localized("done")) {
                    saveAndDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 420, height: 420)
        .onAppear {
            accounts = AccountConfigStore.loadAccounts()
            if accounts.isEmpty {
                accounts = [AccountConfig.newDefault()]
            }
        }
        .alert(item: $pendingDeleteAccount) { account in
            Alert(
                title: Text(L10n.localized("delete_account_title")),
                message: Text(
                    String(
                        format: L10n.localized("delete_account_message"),
                        account.displayName
                    )
                ),
                primaryButton: .destructive(Text(L10n.localized("delete"))) {
                    removeAccount(id: account.id)
                },
                secondaryButton: .cancel(Text(L10n.localized("cancel")))
            )
        }
    }
    
    private func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
    }
    
    private func saveAndDismiss() {
        errorMessage = nil
        
        guard let validationError = validateAccounts(accounts) else {
            do {
                try AccountConfigStore.saveAccounts(accounts)
                NotificationCenter.default.post(name: .refreshUsage, object: nil)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }
        
        errorMessage = validationError
    }
    
    private func validateAccounts(_ accounts: [AccountConfig]) -> String? {
        if accounts.isEmpty {
            return L10n.localized("no_accounts_added")
        }
        
        for account in accounts where account.isEnabled {
            if account.name.trimmed.isEmpty {
                return L10n.localized("account_name_required")
            }
            if account.authToken.trimmed.isEmpty {
                return L10n.localized("auth_token_required")
            }
        }
        
        return nil
    }
}

private struct AccountEditorRow: View {
    @Binding var account: AccountConfig
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(L10n.localized("account_name_placeholder"), text: $account.name)
                .textFieldStyle(.roundedBorder)
            
            SecureField(L10n.localized("auth_token_placeholder"), text: $account.authToken)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Toggle(L10n.localized("enabled"), isOn: $account.isEnabled)
                    .toggleStyle(.switch)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Label(L10n.localized("delete"), systemImage: "trash")
                }
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
