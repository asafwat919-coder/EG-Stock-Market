import Foundation

struct IntradayPoint: Identifiable, Hashable {
    /// Minutes since the 10:00 open.
    let minute: Int
    var price: Double
    var volume: Double

    var id: Int { minute }
}

/// Source of market data. `SimulatedMarketFeed` is the built-in implementation;
/// a licensed EGX data vendor can be plugged in by conforming to this protocol.
protocol MarketFeed: AnyObject {
    var isSimulated: Bool { get }
    var sessionDate: Date { get }
    var stocks: [Stock] { get }
    func dailyHistory(for symbol: String) -> [Candle]
    func intraday(for symbol: String) -> [IntradayPoint]
    func quote(for symbol: String) -> Quote?
    /// Advances the feed. Returns `true` when prices changed.
    func tick(now: Date) -> Bool
}

/// Generates realistic, deterministic EGX price action.
///
/// * Daily history: geometric Brownian motion with a stock-specific drift and a
///   slow business cycle, rescaled so the last close matches the reference price.
/// * Intraday: minute bars driven by a shared market factor (so the indices move
///   coherently) plus idiosyncratic noise, with a U-shaped volume profile.
/// * Live ticks: small correlated moves applied every refresh.
final class SimulatedMarketFeed: MarketFeed {
    let isSimulated = true
    let stocks: [Stock]
    private(set) var sessionDate: Date

    private var histories: [String: [Candle]] = [:]
    private var intradays: [String: [IntradayPoint]] = [:]
    private var quotes: [String: Quote] = [:]
    private var rng: SplitMix64
    private var tickCounter = 0
    private let ticksPerMinute = 4
    private let marketCorrelation = 0.45
    private let historyLength = 1_300

    init(stocks: [Stock] = EGXUniverse.stocks, now: Date = Date(), simulateWhenClosed: Bool = true) {
        self.stocks = stocks
        self.sessionDate = MarketClock.latestSessionDate(from: now)
        self.rng = SplitMix64(seed: UInt64(now.timeIntervalSince1970 * 1000))

        let session = MarketClock.session(at: now)
        let isToday = MarketClock.calendar.isDate(sessionDate, inSameDayAs: now)
        let initialMinutes: Int
        if isToday && session == .open {
            initialMinutes = MarketClock.sessionMinute(at: now) + 1
        } else if simulateWhenClosed {
            // Replay the session up to early afternoon, then keep it trading live.
            initialMinutes = 150
        } else {
            initialMinutes = MarketClock.sessionLength + 1
        }

        let days = MarketClock.tradingDays(before: sessionDate, count: historyLength)
        let marketPath = Self.marketFactor(day: sessionDate, minutes: MarketClock.sessionLength + 1)

        for stock in stocks {
            let history = Self.generateHistory(for: stock, days: days)
            histories[stock.symbol] = history
            let previousClose = history.last?.close ?? stock.referencePrice
            let intraday = Self.generateIntraday(
                for: stock, day: sessionDate, previousClose: previousClose,
                averageVolume: Self.averageVolume(history), minutes: initialMinutes,
                marketPath: marketPath, correlation: marketCorrelation
            )
            intradays[stock.symbol] = intraday
            quotes[stock.symbol] = Self.makeQuote(symbol: stock.symbol, previousClose: previousClose, intraday: intraday, at: now)
        }
    }

    // MARK: MarketFeed

    func dailyHistory(for symbol: String) -> [Candle] { histories[symbol] ?? [] }
    func intraday(for symbol: String) -> [IntradayPoint] { intradays[symbol] ?? [] }
    func quote(for symbol: String) -> Quote? { quotes[symbol] }

    func tick(now: Date) -> Bool {
        tickCounter += 1
        let appendMinute = tickCounter % ticksPerMinute == 0
        let marketShock = rng.gaussian()
        let rho = marketCorrelation

        for stock in stocks {
            guard var points = intradays[stock.symbol], var last = points.last,
                  let previousClose = histories[stock.symbol]?.last?.close else { continue }

            let sigma = stock.dailyVolatility / sqrt(Double(MarketClock.sessionLength * ticksPerMinute))
            let shock = sqrt(rho) * marketShock + sqrt(1 - rho) * rng.gaussian()
            // Gentle pull back toward the open keeps long sessions from drifting unrealistically.
            let open = points.first?.price ?? last.price
            let reversion = -0.002 * log(last.price / open)
            var price = last.price * exp(reversion + sigma * shock)
            price = Self.clampToLimits(Self.roundToTick(price), previousClose: previousClose)

            let averageMinuteVolume = Self.averageVolume(histories[stock.symbol] ?? []) / Double(MarketClock.sessionLength)
            let tickVolume = (averageMinuteVolume / Double(ticksPerMinute)) * rng.uniform(0.3, 1.8)

            if appendMinute && last.minute < MarketClock.sessionLength {
                points.append(IntradayPoint(minute: last.minute + 1, price: price, volume: tickVolume))
            } else {
                last.price = price
                last.volume += tickVolume
                points[points.count - 1] = last
            }
            intradays[stock.symbol] = points

            if var quote = quotes[stock.symbol] {
                let delta = price - quote.price
                quote.price = price
                quote.high = max(quote.high, price)
                quote.low = min(quote.low, price)
                quote.volume += tickVolume
                let spread = Self.spread(for: price)
                quote.bid = Self.roundToTick(price - spread / 2)
                quote.ask = Self.roundToTick(quote.bid + spread)
                quote.updatedAt = now
                quote.lastTick = delta
                quotes[stock.symbol] = quote
            }
        }
        return true
    }

    // MARK: Generation

    static func generateHistory(for stock: Stock, days: [Date]) -> [Candle] {
        var rng = SplitMix64(seed: StableHash.of(stock.symbol))
        let vol = stock.dailyVolatility
        let dailyDrift = rng.uniform(-0.05, 0.42) / 250
        let cyclePeriod = rng.uniform(70, 240)
        let cyclePhase = rng.uniform(0, 2 * .pi)
        let cycleStrength = vol * rng.uniform(0.08, 0.22)

        var closes: [Double] = []
        var returns: [Double] = []
        closes.reserveCapacity(days.count)
        returns.reserveCapacity(days.count)

        var price = 100.0
        for i in days.indices {
            let cycle = cycleStrength * sin(2 * .pi * Double(i) / cyclePeriod + cyclePhase)
            // Occasional fat-tailed days, common on EGX around macro news.
            let jump = rng.unit() < 0.015 ? rng.gaussian() * vol * 2.5 : 0
            let r = dailyDrift + cycle + vol * rng.gaussian() + jump
            price *= exp(r)
            closes.append(price)
            returns.append(r)
        }

        let scale = stock.referencePrice / (closes.last ?? 1)
        let baseVolume = stock.sharesOutstandingM * 1_000_000 * rng.uniform(0.0006, 0.0018)
        var candles: [Candle] = []
        candles.reserveCapacity(days.count)

        for (i, day) in days.enumerated() {
            let close = roundToTick(closes[i] * scale)
            let previous = i == 0 ? close / exp(returns[i]) : closes[i - 1] * scale
            let open = roundToTick(previous * (1 + rng.gaussian() * vol * 0.25))
            let high = roundToTick(max(open, close) * (1 + abs(rng.gaussian()) * vol * 0.45))
            let low = roundToTick(min(open, close) * (1 - abs(rng.gaussian()) * vol * 0.45))
            let activity = 0.6 + min(abs(returns[i]) / vol, 4) * 0.35
            let volume = (baseVolume * activity * exp(rng.gaussian() * 0.35)).rounded()
            let timestamp = MarketClock.timestamp(day: day, sessionMinute: MarketClock.sessionLength)
            candles.append(Candle(date: timestamp, open: open, high: high, low: low, close: close, volume: volume))
        }
        return candles
    }

    static func marketFactor(day: Date, minutes: Int) -> [Double] {
        var rng = SplitMix64(seed: StableHash.of(day: day))
        let bias = rng.gaussian() * 0.35
        return (0..<minutes).map { _ in rng.gaussian() + bias / sqrt(Double(minutes)) * 4 }
    }

    static func generateIntraday(for stock: Stock, day: Date, previousClose: Double, averageVolume: Double,
                                 minutes: Int, marketPath: [Double], correlation rho: Double) -> [IntradayPoint] {
        var rng = SplitMix64(seed: StableHash.of(stock.symbol) ^ StableHash.of(day: day))
        let sessionLength = Double(MarketClock.sessionLength)
        let sigma = stock.dailyVolatility / sqrt(sessionLength)
        let gap = rng.gaussian() * stock.dailyVolatility * 0.3
        let dailyVolume = averageVolume * exp(rng.gaussian() * 0.3)

        var price = clampToLimits(roundToTick(previousClose * (1 + gap)), previousClose: previousClose)
        var points: [IntradayPoint] = []
        points.reserveCapacity(minutes)

        for minute in 0..<minutes {
            if minute > 0 {
                let market = minute < marketPath.count ? marketPath[minute] : rng.gaussian()
                let shock = sqrt(rho) * market + sqrt(1 - rho) * rng.gaussian()
                price = clampToLimits(roundToTick(price * exp(sigma * shock)), previousClose: previousClose)
            }
            // U-shaped intraday volume: busy open and close, quieter midday.
            let x = Double(minute) / sessionLength
            let profile = 0.55 + 1.6 * pow(x - 0.5, 2) * 4 / 2
            let volume = (dailyVolume / sessionLength * profile * rng.uniform(0.4, 1.6)).rounded()
            points.append(IntradayPoint(minute: minute, price: price, volume: volume))
        }
        return points
    }

    static func makeQuote(symbol: String, previousClose: Double, intraday: [IntradayPoint], at date: Date) -> Quote {
        let price = intraday.last?.price ?? previousClose
        let prices = intraday.map(\.price)
        let spread = spread(for: price)
        let bid = roundToTick(price - spread / 2)
        return Quote(
            symbol: symbol,
            price: price,
            previousClose: previousClose,
            open: intraday.first?.price ?? previousClose,
            high: prices.max() ?? price,
            low: prices.min() ?? price,
            volume: intraday.reduce(0) { $0 + $1.volume },
            bid: bid,
            ask: roundToTick(bid + spread),
            updatedAt: date
        )
    }

    static func averageVolume(_ candles: [Candle]) -> Double {
        let recent = candles.suffix(20)
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0) { $0 + $1.volume } / Double(recent.count)
    }

    static func roundToTick(_ price: Double) -> Double {
        (price * 100).rounded() / 100
    }

    static func spread(for price: Double) -> Double {
        max(0.01, roundToTick(price * 0.0008))
    }

    /// EGX applies daily price limits; ±10% is used here for simplicity.
    static func clampToLimits(_ price: Double, previousClose: Double) -> Double {
        min(max(price, roundToTick(previousClose * 0.9)), roundToTick(previousClose * 1.1))
    }
}
