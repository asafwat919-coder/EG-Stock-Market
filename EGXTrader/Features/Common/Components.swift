import SwiftUI
import Charts

/// Rounded gradient badge with the ticker's initials, colored by sector.
struct StockAvatar: View {
    let stock: Stock
    var size: CGFloat = 40

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(LinearGradient(colors: stock.sector.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay {
                Text(stock.initials)
                    .font(.display(size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

/// `+1.25%` pill tinted green / red / grey.
struct ChangeBadge: View {
    let percent: Double
    var filled = true

    var body: some View {
        Text(Fmt.percent(percent))
            .font(.numeric(13, weight: .semibold))
            .foregroundStyle(filled ? .white : Theme.trend(percent))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 72, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(filled ? Theme.trend(percent) : Theme.trend(percent).opacity(0.12))
            )
    }
}

/// Minimal line chart without axes.
struct Sparkline: View {
    let values: [Double]
    var color: Color = Theme.gold
    var baseline: Double?

    var body: some View {
        let points = Self.downsample(values, to: 60)
        let low = min(points.min() ?? 0, baseline ?? .infinity)
        let high = max(points.max() ?? 1, baseline ?? -.infinity)
        Chart {
            if let baseline {
                RuleMark(y: .value("Prev close", baseline))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
            }
            ForEach(Array(points.enumerated()), id: \.offset) { item in
                LineMark(x: .value("t", item.offset), y: .value("v", item.element))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: low...max(high, low + 0.0001))
        .accessibilityHidden(true)
    }

    static func downsample(_ values: [Double], to count: Int) -> [Double] {
        guard values.count > count, count > 1 else { return values }
        let step = Double(values.count - 1) / Double(count - 1)
        return (0..<count).map { values[Int((Double($0) * step).rounded())] }
    }
}

/// One row in a stock list: avatar, name, sparkline, price and change.
struct StockRow: View {
    @Environment(MarketStore.self) private var market
    let stock: Stock

    var body: some View {
        let quote = market.quote(stock.symbol)
        HStack(spacing: Theme.Spacing.m) {
            StockAvatar(stock: stock)
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(stock.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Spacing.s)
            Sparkline(
                values: market.intraday(for: stock.symbol).map(\.price),
                color: Theme.trend(quote?.change ?? 0),
                baseline: quote?.previousClose
            )
            .frame(width: 56, height: 26)
            VStack(alignment: .trailing, spacing: 4) {
                Text(quote.map { Fmt.price($0.price) } ?? "--")
                    .font(.numeric(15))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                ChangeBadge(percent: quote?.changePercent ?? 0)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Card container used across screens.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                            .strokeBorder(Theme.stroke)
                    )
            )
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(20))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}

/// Banner reminding users that prices are simulated.
struct SimulatedDataNotice: View {
    var body: some View {
        Label("Simulated prices for demo purposes, not live EGX data.", systemImage: "info.circle")
            .font(.system(size: 12))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.small).fill(Theme.goldSoft))
    }
}
