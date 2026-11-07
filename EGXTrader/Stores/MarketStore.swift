import Foundation
import Observation

/// App-wide market state. Wraps a `MarketFeed`, ticks it while the app is
/// active and publishes quotes, indices, breadth and movers to SwiftUI.
@Observable
final class MarketStore {
    enum MoverKind: String, CaseIterable, Identifiable {
        case gainers = "Gainers"
        case losers = "Losers"
        case active = "Most Active"
        var id: String { rawValue }
    }

    private(set) var quotes: [String: Quote] = [:]
    private(set) var indices: [MarketIndex] = []
    private(set) var session: MarketSession = .closed
    private(set) var statusDetail = ""
    private(set) var lastUpdated = Date()
    /// Bumped on every tick so views reading feed data (charts) refresh too.
    private(set) var revision = 0

    private let feed: MarketFeed
    @ObservationIgnored private var loop: Task<Void, Never>?
    let tickInterval: Duration

    init(feed: MarketFeed = SimulatedMarketFeed(), tickInterval: Duration = .milliseconds(1500)) {
        self.feed = feed
        self.tickInterval = tickInterval
        publish(now: Date())
    }

    var stocks: [Stock] { feed.stocks }
    var isSimulated: Bool { feed.isSimulated }
    var sessionDate: Date { feed.sessionDate }

    func stock(_ symbol: String) -> Stock? { EGXUniverse.bySymbol[symbol] }
    func quote(_ symbol: String) -> Quote? { quotes[symbol] }

    func intraday(for symbol: String) -> [IntradayPoint] {
        _ = revision
        return feed.intraday(for: symbol)
    }

    func dailyHistory(for symbol: String) -> [Candle] {
        _ = revision
        return feed.dailyHistory(for: symbol)
    }

    // MARK: Live updates

    func start() {
        guard loop == nil else { return }
        loop = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.tickInterval else { return }
                try? await Task.sleep(for: interval)
                self?.step()
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    func step(now: Date = Date()) {
        if feed.tick(now: now) { publish(now: now) }
    }

    private func publish(now: Date) {
        var next: [String: Quote] = [:]
        for stock in feed.stocks {
            if let quote = feed.quote(for: stock.symbol) { next[stock.symbol] = quote }
        }
        quotes = next
        indices = EGXUniverse.indices.map { buildIndex($0) }
        session = MarketClock.session(at: now)
        statusDetail = MarketClock.statusDetail(at: now)
        lastUpdated = now
        revision &+= 1
    }

    // MARK: Derived data

    var breadth: MarketBreadth {
        var up = 0, down = 0, flat = 0
        for quote in quotes.values {
            if quote.change > 0.0001 { up += 1 } else if quote.change < -0.0001 { down += 1 } else { flat += 1 }
        }
        return MarketBreadth(advancers: up, decliners: down, unchanged: flat)
    }

    var totalTurnover: Double { quotes.values.reduce(0) { $0 + $1.turnover } }

    func movers(_ kind: MoverKind, limit: Int = 5) -> [Stock] {
        let pairs = stocks.compactMap { stock in quotes[stock.symbol].map { (stock, $0) } }
        let sorted: [(Stock, Quote)]
        switch kind {
        case .gainers: sorted = pairs.sorted { $0.1.changePercent > $1.1.changePercent }
        case .losers: sorted = pairs.sorted { $0.1.changePercent < $1.1.changePercent }
        case .active: sorted = pairs.sorted { $0.1.turnover > $1.1.turnover }
        }
        return sorted.prefix(limit).map(\.0)
    }

    var sectors: [SectorPerformance] {
        Sector.allCases.compactMap { sector in
            let members = stocks.filter { $0.sector == sector }.compactMap { quotes[$0.symbol] }
            guard !members.isEmpty else { return nil }
            let average = members.reduce(0) { $0 + $1.changePercent } / Double(members.count)
            let turnover = members.reduce(0) { $0 + $1.turnover }
            return SectorPerformance(sector: sector, changePercent: average, turnover: turnover, constituents: members.count)
        }
        .sorted { $0.changePercent > $1.changePercent }
    }

    /// Index level is the reference value scaled by the constituents' move since
    /// the previous close (market-cap or equal weighted).
    private func buildIndex(_ definition: EGXUniverse.IndexDefinition) -> MarketIndex {
        let members = stocks.filter(definition.includes)
        let paths = members.map { feed.intraday(for: $0.symbol) }
        let previousCloses = members.map { feed.dailyHistory(for: $0.symbol).last?.close ?? $0.referencePrice }
        let length = paths.map(\.count).min() ?? 0

        func ratio(prices: [Double]) -> Double {
            guard !members.isEmpty else { return 1 }
            if definition.capWeighted {
                var now = 0.0, before = 0.0
                for (i, stock) in members.enumerated() {
                    now += stock.sharesOutstandingM * prices[i]
                    before += stock.sharesOutstandingM * previousCloses[i]
                }
                return before == 0 ? 1 : now / before
            }
            var sum = 0.0
            for i in members.indices where previousCloses[i] > 0 { sum += prices[i] / previousCloses[i] }
            return sum / Double(members.count)
        }

        let path: [Double] = (0..<length).map { minute in
            definition.referenceValue * ratio(prices: paths.map { $0[minute].price })
        }
        let current = ratio(prices: members.enumerated().map { i, stock in
            quotes[stock.symbol]?.price ?? previousCloses[i]
        })
        return MarketIndex(
            code: definition.code,
            name: definition.name,
            baseValue: definition.referenceValue,
            value: definition.referenceValue * current,
            previousClose: definition.referenceValue,
            intraday: path
        )
    }
}
