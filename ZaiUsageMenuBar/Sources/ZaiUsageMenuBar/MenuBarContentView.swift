import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var viewModel = UsageViewModel()
    @State private var showSettings = false
    @State private var expandedAccounts: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(lastUpdated: viewModel.dashboard?.lastUpdated, isLoading: viewModel.isLoading, showSettings: $showSettings, onRefresh: viewModel.refresh)

            ScrollView {
                VStack(spacing: 8) {
                    if let error = viewModel.error {
                        ErrorView(message: error, retryAction: viewModel.refresh)
                    }

                    if let dashboard = viewModel.dashboard {
                        ForEach(dashboard.accounts) { result in
                            AccountSectionView(
                                result: result,
                                isExpanded: expandedAccounts.contains(result.id),
                                onToggle: { toggleAccount(result.id) }
                            )
                        }
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
        .onChange(of: viewModel.dashboard?.accounts.count) {
            if let accounts = viewModel.dashboard?.accounts {
                expandedAccounts = Set(accounts.map(\.id))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func toggleAccount(_ id: String) {
        if expandedAccounts.contains(id) {
            expandedAccounts.remove(id)
        } else {
            expandedAccounts.insert(id)
        }
    }
}

struct HeaderView: View {
    let lastUpdated: Date?
    let isLoading: Bool
    @Binding var showSettings: Bool
    var onRefresh: (() -> Void)?

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
                onRefresh?()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(L10n.localized("refresh"))

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

struct TokenRingView: View {
    let percentage: Double
    let color: Color
    let size: CGFloat

    init(percentage: Double, color: Color, size: CGFloat = 24) {
        self.percentage = min(max(percentage, 0), 100)
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotation(.degrees(-90))
            Text(String(format: "%.0f", percentage))
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

struct AccountSectionView: View {
    let result: AccountUsageResult
    let isExpanded: Bool
    let onToggle: () -> Void

    private var tokenPercentage: Double? {
        UsageAggregation.tokenPercentage(from: result.usage?.quotaLimits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onToggle) {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(result.account.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    if let tokenPercentage = tokenPercentage {
                        Text(String(format: "%.0f%%", tokenPercentage))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(progressColor(for: tokenPercentage))
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                if let usage = result.usage {
                    if let limits = usage.quotaLimits.limits, !limits.isEmpty {
                        QuotaLimitsView(quotaData: usage.quotaLimits)
                    }

                    if usage.modelUsage.totalUsage != nil {
                        ModelUsageView(modelData: usage.modelUsage)
                    }

                    if usage.toolUsage.totalUsage != nil {
                        ToolUsageView(toolData: usage.toolUsage)
                    }
                } else if let error = result.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
    }
}

struct QuotaLimitsView: View {
    let quotaData: QuotaLimitData

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

            ForEach(Array(quotaData.limits?.enumerated() ?? [].enumerated()), id: \.offset) { _, limit in
                QuotaLimitRow(limit: limit, label: labelForLimit(limit))
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.10))
        .cornerRadius(6)
    }

    private func labelForLimit(_ limit: QuotaLimit) -> String {
        if limit.type == "TOKENS_LIMIT" {
            if limit.unit == 6 { return L10n.localized("weekly_token_label") }
            return L10n.localized("token_label")
        }
        if limit.type == "TIME_LIMIT" {
            return L10n.localized("mcp_label")
        }
        return limit.type ?? ""
    }
}

struct QuotaLimitRow: View {
    let limit: QuotaLimit
    let label: String

    var resetDate: Date? {
        guard let nextResetTime = limit.nextResetTime else { return nil }
        return Date(timeIntervalSince1970: nextResetTime / 1000)
    }

    var body: some View {
        let color = progressColor(for: limit.percentage)
        return VStack(alignment: .leading, spacing: 3) {
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
                        .foregroundColor(color)
                }
            }

            if let percentage = limit.percentage {
                ProgressView(value: min(percentage, 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
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
                    Text(formatTokenCount(tokens))
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
        .background(Color.white.opacity(0.10))
        .cornerRadius(6)
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
        .background(Color.white.opacity(0.10))
        .cornerRadius(6)
    }
}

private let accountColorPalette: [Color] = [
    Color(red: 10/255, green: 132/255, blue: 1),      // Blue #0a84ff
    Color(red: 255/255, green: 159/255, blue: 10/255), // Orange #ff9f0a
    Color(red: 48/255, green: 209/255, blue: 88/255),  // Green #30d158
    Color(red: 94/255, green: 92/255, blue: 230/255),  // Purple #5e5ce6
    Color(red: 100/255, green: 210/255, blue: 255/255),// Cyan #64d2ff
    Color(red: 255/255, green: 55/255, blue: 95/255),  // Pink #ff375f
]

func accountColor(for index: Int) -> Color {
    accountColorPalette[index % accountColorPalette.count]
}

func progressColor(for percentage: Double?, accountAccent: Color) -> Color {
    guard let percentage else { return accountAccent }
    if percentage >= 90 { return Color(red: 255/255, green: 69/255, blue: 58/255) }
    if percentage >= 70 { return Color(red: 255/255, green: 159/255, blue: 10/255) }
    return accountAccent
}

func formatTokenCount(_ count: Int) -> String {
    if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
    if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
    return "\(count)"
}
