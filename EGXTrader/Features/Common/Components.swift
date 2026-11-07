import SwiftUI
import Charts

/// Rounded gradient badge with the ticker's initials, colored by sector.
struct StockAvatar: View {
    let stock: Stock
    var size: CGFloat = 42

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(LinearGradient(colors: stock.sector.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
            .overlay {
                Text(stock.initials)
                    .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            }
            .frame(width: size, height: size)
            .shadow(color: stock.sector.colors[0].opacity(0.35), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}

/// `▲ 1.25%` pill tinted green / red / grey.
struct ChangePill: View {
    let percent: Double
    var style: Style = .soft
    var size: CGFloat = 13

    enum Style { case soft, solid }

    var body: some View {
        let color = Theme.trend(percent)
        HStack(spacing: 3) {
            Image(systemName: percent > 0.00001 ? "arrowtriangle.up.fill" : percent < -0.00001 ? "arrowtriangle.down.fill" : "minus")
                .font(.system(size: size * 0.6, weight: .bold))
            Text(Fmt.percent(abs(percent), signed: false))
                .font(.numeric(size, weight: .semibold))
                .contentTransition(.numericText(value: percent))
        }
        .foregroundStyle(style == .solid ? .white : color)
        .padding(.horizontal, size * 0.62)
        .padding(.vertical, size * 0.32)
        .background(Capsule(style: .continuous).fill(style == .solid ? color : color.opacity(0.14)))
        .animation(.snappy, value: percent)
    }
}

/// Line chart without axes, optionally with a soft gradient fill and a
/// dotted previous-close baseline.
struct Sparkline: View {
    let values: [Double]
    var color: Color = Theme.gold
    var baseline: Double?
    var filled = false
    var lineWidth: CGFloat = 1.6
    var samples = 60

    var body: some View {
        let points = Self.downsample(values, to: samples)
        let low = min(points.min() ?? 0, baseline ?? .infinity)
        let high = max(points.max() ?? 1, baseline ?? -.infinity)
        let pad = max((high - low) * 0.06, 0.0001)
        Chart {
            if let baseline {
                RuleMark(y: .value("Prev close", baseline))
                    .foregroundStyle(Theme.textTertiary.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
            }
            ForEach(Array(points.enumerated()), id: \.offset) { item in
                if filled {
                    AreaMark(x: .value("t", item.offset), yStart: .value("base", low - pad), yEnd: .value("v", item.element))
                        .foregroundStyle(LinearGradient(colors: [color.opacity(0.32), color.opacity(0.0)],
                                                        startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                }
                LineMark(x: .value("t", item.offset), y: .value("v", item.element))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: 0...max(points.count - 1, 1))
        .chartYScale(domain: (low - pad)...(high + pad))
        .accessibilityHidden(true)
    }

    static func downsample(_ values: [Double], to count: Int) -> [Double] {
        guard values.count > count, count > 1 else { return values }
        let step = Double(values.count - 1) / Double(count - 1)
        return (0..<count).map { values[Int((Double($0) * step).rounded())] }
    }
}

/// Price text that briefly flashes green or red when it ticks.
struct FlashingPrice: View {
    let price: Double?
    var font: Font = .numeric(16)
    var prefix = ""

    @State private var flash: Color = .clear

    var body: some View {
        Text(price.map { prefix + Fmt.price($0) } ?? "--")
            .font(font)
            .foregroundStyle(Theme.textPrimary)
            .contentTransition(.numericText(value: price ?? 0))
            .animation(.snappy(duration: 0.3), value: price)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(flash))
            .padding(.horizontal, -5)
            .onChange(of: price) { old, new in
                guard let old, let new, old != new else { return }
                flash = (new > old ? Theme.positive : Theme.negative).opacity(0.22)
                withAnimation(.easeOut(duration: 0.8)) { flash = .clear }
            }
    }
}

/// One row in a stock list: avatar, name, sparkline, flashing price and change.
struct StockRow: View {
    @Environment(MarketStore.self) private var market
    let stock: Stock
    var showsSparkline = true

    var body: some View {
        let quote = market.quote(stock.symbol)
        HStack(spacing: Theme.Spacing.m) {
            StockAvatar(stock: stock)
            VStack(alignment: .leading, spacing: 3) {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(stock.name)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsSparkline {
                Sparkline(
                    values: market.intraday(for: stock.symbol).map(\.price),
                    color: Theme.trend(quote?.change ?? 0),
                    baseline: quote?.previousClose,
                    filled: true,
                    lineWidth: 1.4,
                    samples: 40
                )
                .frame(width: 62, height: 30)
            }
            VStack(alignment: .trailing, spacing: 5) {
                FlashingPrice(price: quote?.price, font: .numeric(15.5))
                ChangePill(percent: quote?.changePercent ?? 0, size: 11.5)
            }
            .frame(minWidth: 82, alignment: .trailing)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Section title with an optional trailing accessory.
struct SectionHeader<Accessory: View>: View {
    let title: String
    var overline: String?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                if let overline {
                    Text(overline.uppercased())
                        .font(.overline)
                        .foregroundStyle(Theme.gold)
                        .tracking(1.2)
                }
                Text(title)
                    .font(.serif(22))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            accessory
        }
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(title: String, overline: String? = nil) {
        self.init(title: title, overline: overline) { EmptyView() }
    }
}

/// Capsule segmented control with a sliding selection.
struct CapsuleSegmented<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String
    var compact = false

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    withAnimation(.snappy(duration: 0.28)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: compact ? 12.5 : 13.5, weight: .semibold))
                        .foregroundStyle(selected ? Theme.onGold : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 7 : 9)
                        .background {
                            if selected {
                                Capsule(style: .continuous)
                                    .fill(Theme.goldGradient)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                                    .shadow(color: Theme.gold.opacity(0.3), radius: 6, y: 2)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule(style: .continuous).fill(Theme.surfaceMuted))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Low–high range bar with a marker at the current value (day range, 52-week range).
struct RangeBar: View {
    let title: String
    let low: Double
    let high: Double
    let current: Double

    var body: some View {
        let span = max(high - low, 0.0001)
        let fraction = min(max((current - low) / span, 0), 1)
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.overline)
                .tracking(1)
                .foregroundStyle(Theme.textTertiary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceMuted)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.negative, Theme.warning, Theme.positive],
                                             startPoint: .leading, endPoint: .trailing))
                        .opacity(0.85)
                    Circle()
                        .fill(Theme.textPrimary)
                        .overlay(Circle().strokeBorder(Theme.surface, lineWidth: 3))
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .offset(x: fraction * (proxy.size.width - 16))
                        .animation(.snappy, value: fraction)
                }
            }
            .frame(height: 16)
            HStack {
                Text(Fmt.price(low))
                Spacer()
                Text(Fmt.price(high))
            }
            .font(.numeric(12, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
        }
    }
}

/// Small label + value tile.
struct StatTile: View {
    let title: String
    let value: String
    var tint: Color = Theme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.overline)
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
            Text(value)
                .font(.numeric(15))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Pulsing dot used for "live" indicators.
struct LiveDot: View {
    var color: Color = Theme.positive
    var active = true
    @State private var pulse = false

    var body: some View {
        ZStack {
            if active {
                Circle()
                    .fill(color.opacity(0.35))
                    .frame(width: 16, height: 16)
                    .scaleEffect(pulse ? 1 : 0.4)
                    .opacity(pulse ? 0 : 1)
            }
            Circle().fill(active ? color : Theme.textTertiary).frame(width: 7, height: 7)
        }
        .frame(width: 16, height: 16)
        .onAppear {
            guard active else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

/// Banner reminding users that prices are simulated.
struct SimulatedDataNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.gold)
            Text("Prices are simulated for demonstration and are not live EGX quotes. Nothing here is investment advice.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous).fill(Theme.goldSoft))
    }
}

/// Divider that respects the card inset.
struct RowDivider: View {
    var inset: CGFloat = 54

    var body: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
