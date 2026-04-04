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
            Text(L10n.localized("app_title"))
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
            .help(L10n.localized("settings"))
            
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(L10n.localized("quit"))
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
            Button(L10n.localized("retry"), action: retryAction)
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
                Text(L10n.localized("quota"))
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
                QuotaLimitRow(limit: tokenLimit, label: L10n.localized("token_label"))
            }
            
            if let timeLimit = timeLimit {
                QuotaLimitRow(limit: timeLimit, label: L10n.localized("mcp_label"))
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
                    Text("\(L10n.localized("resets_prefix")) \(resetDate, style: .relative)")
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
                Text(L10n.localized("model_usage"))
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
                Text(L10n.localized("tools"))
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let totalUsage = toolData.totalUsage, let searchCount = totalUsage.totalSearchMcpCount {
                    Text("\(searchCount) \(L10n.localized("calls_suffix"))")
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
