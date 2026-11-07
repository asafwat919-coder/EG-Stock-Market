import XCTest
@testable import EGXTrader

final class MarketClockTests: XCTestCase {
    private func cairoDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        MarketClock.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testWeekendIsClosed() {
        // 6 Nov 2026 is a Friday, 7 Nov a Saturday.
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 6, 11, 0)), .closed)
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 7, 11, 0)), .closed)
    }

    func testSessionsOnTradingDay() {
        // 8 Nov 2026 is a Sunday, the first EGX trading day of the week.
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 8, 9, 45)), .preOpen)
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 8, 10, 0)), .open)
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 8, 14, 35)), .closingAuction)
        XCTAssertEqual(MarketClock.session(at: cairoDate(2026, 11, 8, 15, 0)), .closed)
    }

    func testNextOpenSkipsWeekend() {
        let next = MarketClock.nextOpen(after: cairoDate(2026, 11, 5, 16, 0)) // Thursday afternoon
        XCTAssertEqual(next, cairoDate(2026, 11, 8, 10, 0))
    }

    func testTradingDaysAreAscendingWeekdays() {
        let days = MarketClock.tradingDays(before: cairoDate(2026, 11, 8, 12, 0), count: 10)
        XCTAssertEqual(days.count, 10)
        XCTAssertEqual(days, days.sorted())
        XCTAssertTrue(days.allSatisfy(MarketClock.isTradingDay))
    }
}

final class ModelTests: XCTestCase {
    func testFeesRespectMinimumCommission() {
        XCTAssertEqual(FeeSchedule.fees(for: 0), 0)
        XCTAssertEqual(FeeSchedule.fees(for: 1_000), 5 + 1_000 * FeeSchedule.regulatoryRate, accuracy: 1e-9)
        XCTAssertEqual(FeeSchedule.fees(for: 100_000), 100_000 * (FeeSchedule.commissionRate + FeeSchedule.regulatoryRate), accuracy: 1e-9)
    }

    func testSignalThresholds() {
        XCTAssertEqual(Signal.from(score: 60), .strongBuy)
        XCTAssertEqual(Signal.from(score: 20), .buy)
        XCTAssertEqual(Signal.from(score: 0), .hold)
        XCTAssertEqual(Signal.from(score: -20), .sell)
        XCTAssertEqual(Signal.from(score: -80), .strongSell)
    }

    func testUniverseSymbolsAreUnique() {
        XCTAssertEqual(EGXUniverse.bySymbol.count, EGXUniverse.stocks.count)
        XCTAssertTrue(EGXUniverse.defaultWatchlist.allSatisfy { EGXUniverse.bySymbol[$0] != nil })
    }
}

final class SimulatedFeedTests: XCTestCase {
    func testRandomIsDeterministic() {
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        for _ in 0..<100 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testHistoryEndsAtReferencePrice() {
        let stock = EGXUniverse.bySymbol["COMI"]!
        let days = MarketClock.tradingDays(before: Date(), count: 250)
        let history = SimulatedMarketFeed.generateHistory(for: stock, days: days)
        XCTAssertEqual(history.count, 250)
        XCTAssertEqual(history.last!.close, stock.referencePrice, accuracy: 0.01)
        XCTAssertTrue(history.allSatisfy { $0.low <= min($0.open, $0.close) && $0.high >= max($0.open, $0.close) })
    }

    func testTicksStayWithinDailyLimits() {
        let feed = SimulatedMarketFeed()
        for _ in 0..<200 { _ = feed.tick(now: Date()) }
        for stock in feed.stocks {
            let quote = feed.quote(for: stock.symbol)!
            XCTAssertLessThanOrEqual(quote.price, quote.previousClose * 1.1 + 0.01, stock.symbol)
            XCTAssertGreaterThanOrEqual(quote.price, quote.previousClose * 0.9 - 0.01, stock.symbol)
            XCTAssertLessThanOrEqual(quote.bid, quote.ask, stock.symbol)
        }
    }

    func testStorePublishesIndicesAndBreadth() {
        let store = MarketStore()
        XCTAssertEqual(store.indices.count, EGXUniverse.indices.count)
        XCTAssertEqual(store.breadth.advancers + store.breadth.decliners + store.breadth.unchanged, EGXUniverse.stocks.count)
        XCTAssertEqual(store.movers(.gainers, limit: 3).count, 3)
        store.step()
        XCTAssertEqual(store.quotes.count, EGXUniverse.stocks.count)
    }
}
