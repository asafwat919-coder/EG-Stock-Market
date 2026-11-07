import SwiftUI
import Charts

struct StockDetailView: View {
    @Environment(MarketStore.self) private var market
    @Environment(WatchlistStore.self) private var watchlist
    @Environment(PortfolioStore.self) private var portfolio
    let stock: Stock

    @State private var range: ChartRange = .day
    @State private var scrubbed: PricePoint?
    @State private var ticketSide: OrderSide? = LaunchOptions.initialTicket

    var body: some View {
        let quote = market.quote(stock.symbol)
        let points = chartPoints()
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(quote: quote, points: points)
                PriceChart(points: points, previousClose: range == .day ? quote?.previousClose : nil,
                           showsTime: range == .day, scrubbed: $scrubbed)
                    .frame(height: 250)
                CapsuleSegmented(options: ChartRange.allCases, selection: $range, label: \.rawValue, compact: true)
                if let holding = portfolio.holding(stock.symbol), let quote {
                    PositionCard(holding: holding, quote: quote)
                }
                if let quote {
                    rangesCard(quote)
                    PerformanceStrip(history: market.dailyHistory(for: stock.symbol), price: quote.price)
                    OrderBookCard(quote: quote)
                    statsCard(quote)
                }
                aboutCard
                if market.isSimulated { SimulatedDataNotice() }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(stock.symbol).font(.system(size: 15, weight: .bold))
                    Text("EGX · \(stock.sector.displayName)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                let watched = watchlist.contains(stock.symbol)
                Button {
                    withAnimation(.snappy) { watchlist.toggle(stock.symbol) }
                } label: {
                    Image(systemName: watched ? "star.fill" : "star")
                        .foregroundStyle(watched ? Theme.gold : Theme.textPrimary)
                        .symbolEffect(.bounce, value: watched)
                }
                .sensoryFeedback(.impact(weight: .light), trigger: watched)
                .accessibilityLabel(watched ? "Remove from watchlist" : "Add to watchlist")
            }
        }
        .safeAreaInset(edge: .bottom) { tradeBar }
        .sheet(item: $ticketSide) { side in
            OrderTicketView(stock: stock, initialSide: side)
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
    }

    // MARK: Header

    private func header(quote: Quote?, points: [PricePoint]) -> some View {
        let shownPrice = scrubbed?.price ?? quote?.price
        let reference = range == .day ? (quote?.previousClose ?? 0) : (points.first?.price ?? 0)
        let change = (shownPrice ?? 0) - reference
        let percent = reference == 0 ? 0 : change / reference * 100
        return HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(stock.name)
                    .font(.serif(21, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stock.nameAr)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("EGP")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(shownPrice.map(Fmt.price) ?? "--")
                        .font(.numeric(38, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: shownPrice ?? 0))
                        .animation(.snappy(duration: 0.25), value: shownPrice)
                }
                .padding(.top, 6)
                HStack(spacing: 8) {
                    ChangePill(percent: percent, style: .solid, size: 13)
                    Text(Fmt.change(change))
                        .font(.numeric(14, weight: .semibold))
                        .foregroundStyle(Theme.trend(change))
                    Text(scrubbed.map { range == .day ? Fmt.time($0.date) : Fmt.day($0.date) } ?? periodLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer(minLength: 0)
            StockAvatar(stock: stock, size: 54)
        }
    }

    private var periodLabel: String {
        switch range {
        case .day: return "Today"
        case .week: return "Past week"
        case .month: return "Past month"
        case .threeMonths: return "Past 3 months"
        case .year: return "Past year"
        case .fiveYears: return "Past 5 years"
        }
    }

    // MARK: Trade bar

    private var tradeBar: some View {
        HStack(spacing: 12) {
            Button("Sell") { ticketSide = .sell }
                .buttonStyle(PillButtonStyle(kind: .outline))
            Button("Buy \(stock.symbol)") { ticketSide = .buy }
                .buttonStyle(PillButtonStyle(kind: .gold))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(Theme.stroke).frame(height: 1) }
    }

    // MARK: Cards

    private func rangesCard(_ quote: Quote) -> some View {
        let year = market.dailyHistory(for: stock.symbol).suffix(250)
        let yearLow = min(year.map(\.low).min() ?? quote.low, quote.low)
        let yearHigh = max(year.map(\.high).max() ?? quote.high, quote.high)
        return VStack(spacing: 20) {
            RangeBar(title: "Day range", low: quote.low, high: quote.high, current: quote.price)
            RangeBar(title: "52-week range", low: yearLow, high: yearHigh, current: quote.price)
        }
        .cardStyle()
    }

    private func statsCard(_ quote: Quote) -> some View {
        let marketCap = stock.sharesOutstandingM * 1_000_000 * quote.price
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
        return VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Key statistics")
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                StatTile(title: "Open", value: Fmt.price(quote.open))
                StatTile(title: "Prev close", value: Fmt.price(quote.previousClose))
                StatTile(title: "Volume", value: Fmt.compact(quote.volume))
                StatTile(title: "Turnover", value: Fmt.compact(quote.turnover))
                StatTile(title: "Market cap", value: Fmt.compact(marketCap))
                StatTile(title: "P/E", value: String(format: "%.1fx", stock.peRatio))
                StatTile(title: "Div. yield", value: Fmt.percent(stock.dividendYield, signed: false))
                StatTile(title: "Limit up", value: Fmt.price(quote.previousClose * 1.1), tint: Theme.positive)
                StatTile(title: "Limit down", value: Fmt.price(quote.previousClose * 0.9), tint: Theme.negative)
            }
        }
        .cardStyle()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.onGold)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.goldGradient))
                VStack(alignment: .leading, spacing: 1) {
                    Text("AI rating").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    Text("Arriving in the next build").font(.system(size: 12)).foregroundStyle(Theme.gold)
                }
            }
            Text("Trend, momentum, mean-reversion and volume signals combined into a buy / hold / sell rating for \(stock.symbol), with a target price, stop loss and plain-language reasoning.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    // MARK: Data

    private func chartPoints() -> [PricePoint] {
        if range == .day {
            let day = market.sessionDate
            return market.intraday(for: stock.symbol).map {
                PricePoint(date: MarketClock.timestamp(day: day, sessionMinute: $0.minute), price: $0.price)
            }
        }
        var points = market.dailyHistory(for: stock.symbol).suffix(range.tradingDays).map {
            PricePoint(date: $0.date, price: $0.close)
        }
        if let quote = market.quote(stock.symbol) {
            points.append(PricePoint(date: max(quote.updatedAt, (points.last?.date ?? .distantPast) + 60), price: quote.price))
        }
        guard points.count > 260 else { return points }
        let step = Double(points.count - 1) / 259
        return (0..<260).map { points[Int((Double($0) * step).rounded())] }
    }
}

// MARK: - Chart

struct PricePoint: Identifiable, Hashable {
    let date: Date
    let price: Double
    var id: Date { date }
}

struct PriceChart: View {
    let points: [PricePoint]
    var previousClose: Double?
    var showsTime: Bool
    @Binding var scrubbed: PricePoint?

    @State private var selectedDate: Date?

    var body: some View {
        let first = previousClose ?? points.first?.price ?? 0
        let last = points.last?.price ?? 0
        let color = Theme.trend(last - first)
        let prices = points.map(\.price) + (previousClose.map { [$0] } ?? [])
        let low = prices.min() ?? 0
        let high = prices.max() ?? 1
        let padding = max((high - low) * 0.1, 0.01)

        Chart {
            if let previousClose {
                RuleMark(y: .value("Previous close", previousClose))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }
            ForEach(points) { point in
                AreaMark(x: .value("Time", point.date),
                         yStart: .value("Base", low - padding),
                         yEnd: .value("Price", point.price))
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.32), color.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", point.date), y: .value("Price", point.price))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
            }
            if let scrubbed {
                RuleMark(x: .value("Selected", scrubbed.date))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(x: .value("Selected", scrubbed.date), y: .value("Price", scrubbed.price))
                    .symbolSize(110)
                    .foregroundStyle(color)
                    .symbol { Circle().strokeBorder(Theme.surface, lineWidth: 3).background(Circle().fill(color)).frame(width: 14, height: 14) }
            } else if let lastPoint = points.last {
                PointMark(x: .value("Now", lastPoint.date), y: .value("Price", lastPoint.price))
                    .symbol { PulsingMarker(color: color) }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: (low - padding)...(high + padding))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        // Format explicitly in Cairo time; the chart's own formatter uses the device zone.
                        Text(showsTime ? Fmt.time(date) : Fmt.monthYear(date))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4])).foregroundStyle(Theme.stroke)
                AxisValueLabel().foregroundStyle(Theme.textTertiary)
            }
        }
        .environment(\.timeZone, MarketClock.cairo)
        .onChange(of: selectedDate) { _, date in
            guard let date else { scrubbed = nil; return }
            scrubbed = points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        }
        .sensoryFeedback(.selection, trigger: scrubbed?.date)
        .accessibilityLabel("Price chart. Drag to inspect prices.")
    }
}

private struct PulsingMarker: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.3)).frame(width: 22, height: 22)
                .scaleEffect(pulse ? 1.2 : 0.5).opacity(pulse ? 0 : 1)
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

// MARK: - Position

private struct PositionCard: View {
    let holding: Holding
    let quote: Quote

    var body: some View {
        let value = holding.quantity * quote.price
        let gain = value - holding.costBasis
        let gainPercent = holding.costBasis == 0 ? 0 : gain / holding.costBasis * 100
        HStack(spacing: 0) {
            StatTile(title: "Shares", value: Fmt.integer(holding.quantity))
            StatTile(title: "Value", value: Fmt.compact(value))
            StatTile(title: "Return", value: Fmt.percent(gainPercent), tint: Theme.trend(gain))
        }
        .cardStyle()
        .overlay(alignment: .topTrailing) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.gold)
                .padding(12)
        }
    }
}

// MARK: - Performance

private struct PerformanceStrip: View {
    let history: [Candle]
    let price: Double

    var body: some View {
        let periods: [(String, Int)] = [("1W", 5), ("1M", 22), ("3M", 66), ("6M", 125), ("1Y", 250), ("3Y", 750)]
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Performance")
            HStack(spacing: 6) {
                ForEach(periods, id: \.0) { label, days in
                    let base = history.count > days ? history[history.count - days - 1].close : history.first?.close ?? price
                    let change = base == 0 ? 0 : (price - base) / base * 100
                    VStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                        Text(String(format: "%+.1f%%", change))
                            .font(.numeric(12.5, weight: .bold))
                            .foregroundStyle(Theme.trend(change))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.trend(change).opacity(0.1)))
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Order book

private struct OrderBookCard: View {
    let quote: Quote

    var body: some View {
        let levels = Self.levels(for: quote)
        let maxQuantity = (levels.bids + levels.asks).map(\.quantity).max() ?? 1
        let bidTotal = levels.bids.reduce(0) { $0 + $1.quantity }
        let askTotal = levels.asks.reduce(0) { $0 + $1.quantity }
        let bidShare = bidTotal / max(bidTotal + askTotal, 1)

        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Order book", overline: "Depth") {
                Text("Spread " + Fmt.price(quote.spread))
                    .font(.numeric(12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack(spacing: 10) {
                VStack(spacing: 4) {
                    ForEach(levels.bids) { level in
                        row(level, maxQuantity: maxQuantity, color: Theme.positive, alignment: .trailing)
                    }
                }
                VStack(spacing: 4) {
                    ForEach(levels.asks) { level in
                        row(level, maxQuantity: maxQuantity, color: Theme.negative, alignment: .leading)
                    }
                }
            }
            GeometryReader { proxy in
                HStack(spacing: 3) {
                    Capsule().fill(Theme.positive).frame(width: max(4, proxy.size.width * bidShare - 1.5))
                    Capsule().fill(Theme.negative)
                }
            }
            .frame(height: 6)
            HStack {
                Text("Bids \(Fmt.percent(bidShare * 100, signed: false))").foregroundStyle(Theme.positive)
                Spacer()
                Text("Asks \(Fmt.percent((1 - bidShare) * 100, signed: false))").foregroundStyle(Theme.negative)
            }
            .font(.numeric(12, weight: .semibold))
        }
        .cardStyle()
    }

    private func row(_ level: OrderBookLevel, maxQuantity: Double, color: Color, alignment: Alignment) -> some View {
        let isBid = alignment == .trailing
        return ZStack(alignment: alignment) {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: proxy.size.width * level.quantity / maxQuantity)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
            HStack {
                if isBid {
                    Text(Fmt.compact(level.quantity)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Fmt.price(level.price)).foregroundStyle(color)
                } else {
                    Text(Fmt.price(level.price)).foregroundStyle(color)
                    Spacer()
                    Text(Fmt.compact(level.quantity)).foregroundStyle(Theme.textSecondary)
                }
            }
            .font(.numeric(12.5, weight: .semibold))
            .padding(.horizontal, 8)
        }
        .frame(height: 26)
    }

    /// Plausible five-level book around the current bid/ask (simulated feed).
    static func levels(for quote: Quote) -> (bids: [OrderBookLevel], asks: [OrderBookLevel]) {
        var rng = SplitMix64(seed: StableHash.of(quote.symbol) ^ UInt64(max(quote.price, 0) * 100))
        let tick = max(0.01, (quote.price * 0.0006 * 100).rounded() / 100)
        let base = max(quote.volume / 400, 500)
        let bids = (0..<5).map { i in
            OrderBookLevel(id: i, price: quote.bid - Double(i) * tick, quantity: (base * rng.uniform(0.4, 1.6) * (1 + Double(i) * 0.25)).rounded())
        }
        let asks = (0..<5).map { i in
            OrderBookLevel(id: 10 + i, price: quote.ask + Double(i) * tick, quantity: (base * rng.uniform(0.4, 1.6) * (1 + Double(i) * 0.25)).rounded())
        }
        return (bids, asks)
    }
}
