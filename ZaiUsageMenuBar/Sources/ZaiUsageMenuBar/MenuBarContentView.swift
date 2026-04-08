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
                        ForEach(Array(dashboard.accounts.enumerated()), id: \.element.id) { index, result in
                            AccountSectionView(
                                result: result,
                                colorIndex: index,
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
            AsyncImage(url: URL(string: "https://z-cdn.chatglm.cn/z-ai/static/logo.svg")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Z")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            .frame(width: 20, height: 20)

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
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f", percentage))
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

struct AccountSectionView: View {
    let result: AccountUsageResult
    let colorIndex: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    @State private var hourlyRange: HourlyRange = .today(referenceDate: Date())

    private var accentColor: Color { accountColor(for: colorIndex) }

    private var ringPercentageValue: Double? {
        UsageAggregation.ringPercentage(from: result.usage?.quotaLimits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: 10)

                    Text(result.account.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))

                    if let level = result.usage?.quotaLimits.level {
                        Text(level.uppercased())
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }

                    Spacer()

                    if let pct = ringPercentageValue {
                        TokenRingView(
                            percentage: pct,
                            color: progressColor(for: pct, accountAccent: accentColor),
                            size: 24
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    if let usage = result.usage {
                        if let limits = usage.quotaLimits.limits, !limits.isEmpty {
                            QuotaSectionView(quotaData: usage.quotaLimits, accentColor: accentColor)
                        }
                        if let modelData = usage.modelUsage.modelDataList, !modelData.isEmpty {
                            let bars = HourlyBars.from(modelData: usage.modelUsage, range: hourlyRange)
                            let modelNames = modelData.compactMap { $0.modelName }

                            Divider()
                                .background(Color.primary.opacity(0.05))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)

                            HourlyChartView(
                                bars: bars,
                                modelNames: modelNames,
                                range: hourlyRange,
                                onRangeChange: { hourlyRange = $0 }
                            )
                        }
                        if usage.modelUsage.totalUsage != nil || usage.toolUsage.totalUsage != nil {
                            StatsSectionView(usage: usage, accentColor: accentColor)
                        }
                    } else if let error = result.error {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
    }
}

struct QuotaSectionView: View {
    let quotaData: QuotaLimitData
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let limits = quotaData.limits, !limits.isEmpty {
                ForEach(Array(limits.enumerated()), id: \.offset) { _, limit in
                    QuotaBarRow(limit: limit, accentColor: accentColor)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

private struct QuotaBarRow: View {
    let limit: QuotaLimit
    let accentColor: Color

    private var label: String {
        if limit.type == "TOKENS_LIMIT" {
            return limit.unit == 6 ? L10n.localized("weekly_token_label") : L10n.localized("token_label")
        }
        if limit.type == "TIME_LIMIT" { return L10n.localized("mcp_label") }
        return limit.type ?? ""
    }

    private var resetDate: Date? {
        guard let t = limit.nextResetTime else { return nil }
        return Date(timeIntervalSince1970: t / 1000)
    }

    var body: some View {
        let color = progressColor(for: limit.percentage, accountAccent: accentColor)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
                Spacer()
                if let current = limit.currentValue, let usage = limit.usage {
                    Text(String(format: "%.0f/%.0f", current, usage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }

            if let pct = limit.percentage {
                ProgressView(value: min(pct, 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 3)
            }

            if let resetDate = resetDate {
                HStack {
                    Spacer()
                    Text("\(L10n.localized("resets_prefix")) \(resetDate, style: .relative)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.top, 1)
            }
        }
        .padding(.bottom, 4)
    }
}

struct StatsSectionView: View {
    let usage: UsageData
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.primary.opacity(0.05))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

            // Main stats row
            HStack(spacing: 0) {
                if let calls = usage.modelUsage.totalUsage?.totalModelCallCount {
                    StatColumn(value: "\(calls)", label: "Model Calls")
                    Spacer()
                }
                if let totalTools = usage.toolUsage.totalUsage?.totalSearchMcpCount {
                    StatColumn(value: "\(totalTools)", label: "Tool Calls")
                    Spacer()
                }
                if let tokens = usage.modelUsage.totalUsage?.totalTokensUsage {
                    StatColumn(value: formatTokenCount(tokens), label: "Tokens")
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            // Tool breakdown
            if let details = usage.toolUsage.totalUsage?.toolDetails, !details.isEmpty {
                VStack(spacing: 2) {
                    ForEach(details, id: \.self) { detail in
                        HStack {
                            Text(detail.modelName ?? "")
                                .font(.system(size: 9))
                                .foregroundColor(.primary.opacity(0.35))
                            Spacer()
                            Text("\(detail.totalUsageCount ?? 0)")
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundColor(.primary.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
    }
}

private struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary.opacity(0.9))
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.primary.opacity(0.3))
        }
    }
}

let accountColorPalette: [Color] = [
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
