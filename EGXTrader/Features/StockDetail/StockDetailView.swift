import SwiftUI
import Charts

struct StockDetailView: View {
    @Environment(MarketStore.self) private var market
    @Environment(WatchlistStore.self) private var watchlist
    let stock: Stock

    @State private var range: ChartRange = .day

    var body: some View {
        let quote = market.quote(stock.symbol)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header(quote)
                PriceChart(points: chartPoints(), previousClose: range == .day ? quote?.previousClose : nil,
                           showsTime: range == .day)
                    .frame(height: 240)
                Picker("Range", selection: $range) {
                    ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                if let quote { statsCard(quote) }
                aboutCard
                if market.isSimulated { SimulatedDataNotice() }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    watchlist.toggle(stock.symbol)
                } label: {
                    Image(systemName: watchlist.contains(stock.symbol) ? "star.fill" : "star")
                }
                .accessibilityLabel(watchlist.contains(stock.symbol) ? "Remove from watchlist" : "Add to watchlist")
            }
        }
    }

    // MARK: Sections

    private func header(_ quote: Quote?) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            StockAvatar(stock: stock, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.display(18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(stock.nameAr)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                Text(stock.sector.displayName + (stock.isEGX30 ? " · EGX 30" : ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(quote.map { Fmt.egp($0.price) } ?? "--")
                        .font(.numeric(30, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    if let quote {
                        Text("\(Fmt.change(quote.change)) (\(Fmt.percent(quote.changePercent)))")
                            .font(.numeric(14))
                            .foregroundStyle(Theme.trend(quote.change))
                    }
                }
                .padding(.top, Theme.Spacing.s)
            }
        }
        .padding(.top, Theme.Spacing.m)
    }

    private func statsCard(_ quote: Quote) -> some View {
        let marketCap = stock.sharesOutstandingM * 1_000_000 * quote.price
        let stats: [(String, String)] = [
            ("Open", Fmt.price(quote.open)),
            ("Prev close", Fmt.price(quote.previousClose)),
            ("High", Fmt.price(quote.high)),
            ("Low", Fmt.price(quote.low)),
            ("Bid", Fmt.price(quote.bid)),
            ("Ask", Fmt.price(quote.ask)),
            ("Volume", Fmt.compact(quote.volume)),
            ("Turnover", Fmt.compact(quote.turnover)),
            ("Market cap", Fmt.compact(marketCap)),
            ("P/E", String(format: "%.1fx", stock.peRatio)),
            ("Div. yield", Fmt.percent(stock.dividendYield, signed: false)),
            ("Limits ±10%", "\(Fmt.price(quote.previousClose * 0.9))–\(Fmt.price(quote.previousClose * 1.1))"),
        ]
        return Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Key Statistics")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.l), GridItem(.flexible())],
                          alignment: .leading, spacing: Theme.Spacing.m) {
                    ForEach(stats, id: \.0) { item in
                        HStack {
                            Text(item.0).foregroundStyle(Theme.textSecondary)
                            Spacer(minLength: 4)
                            Text(item.1).font(.numeric(13)).foregroundStyle(Theme.textPrimary)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .font(.system(size: 13))
                    }
                }
            }
        }
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Label("AI rating coming soon", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text("The next build adds the technical-indicator engine (RSI, MACD, moving averages, volume) with a buy / hold / sell rating, target price and stop loss for \(stock.symbol).")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
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
            points.append(PricePoint(date: quote.updatedAt, price: quote.price))
        }
        guard points.count > 300 else { return points }
        let step = Double(points.count - 1) / 299
        return (0..<300).map { points[Int((Double($0) * step).rounded())] }
    }
}

struct PricePoint: Identifiable, Hashable {
    let date: Date
    let price: Double
    var id: Date { date }
}

struct PriceChart: View {
    let points: [PricePoint]
    var previousClose: Double?
    var showsTime: Bool

    var body: some View {
        let first = previousClose ?? points.first?.price ?? 0
        let last = points.last?.price ?? 0
        let color = Theme.trend(last - first)
        let prices = points.map(\.price) + (previousClose.map { [$0] } ?? [])
        let low = prices.min() ?? 0
        let high = prices.max() ?? 1
        let padding = max((high - low) * 0.08, 0.01)

        Chart {
            if let previousClose {
                RuleMark(y: .value("Previous close", previousClose))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Base", low - padding),
                    yEnd: .value("Price", point.price)
                )
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.28), color.opacity(0)],
                                                startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
                LineMark(x: .value("Time", point.date), y: .value("Price", point.price))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartYScale(domain: (low - padding)...(high + padding))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.stroke)
                AxisValueLabel(format: showsTime ? .dateTime.hour().minute() : .dateTime.month(.abbreviated).year(.twoDigits))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.stroke)
                AxisValueLabel().foregroundStyle(Theme.textTertiary)
            }
        }
        .environment(\.timeZone, MarketClock.cairo)
        .accessibilityLabel("Price chart")
    }
}
