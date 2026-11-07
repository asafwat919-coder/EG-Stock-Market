import Foundation
import Observation

/// Paper-trading account: virtual EGP cash, holdings and order history,
/// persisted as JSON in `UserDefaults`. Market orders fill instantly at the
/// ask (buys) or bid (sells) with realistic Egyptian brokerage fees.
@Observable
final class PortfolioStore {
    enum OrderError: LocalizedError {
        case invalidQuantity, insufficientCash(needed: Double), insufficientShares(held: Double), marketUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidQuantity: return "Enter a quantity greater than zero."
            case .insufficientCash(let needed): return "Not enough cash. This order needs \(Fmt.egp(needed))."
            case .insufficientShares(let held): return "You only hold \(Fmt.integer(held)) shares."
            case .marketUnavailable: return "No price available for this stock right now."
            }
        }
    }

    private(set) var state: PortfolioState

    private let defaults: UserDefaults
    private static let key = "portfolio.state.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(PortfolioState.self, from: data) {
            state = saved
        } else {
            state = .fresh
        }
    }

    var cash: Double { state.cash }
    var holdings: [Holding] { state.holdings }
    var orders: [Order] { state.orders }

    func holding(_ symbol: String) -> Holding? { state.holdings.first { $0.symbol == symbol } }

    func marketValue(using market: MarketStore) -> Double {
        state.holdings.reduce(0) { $0 + $1.quantity * (market.quote($1.symbol)?.price ?? $1.averageCost) }
    }

    func totalValue(using market: MarketStore) -> Double { state.cash + marketValue(using: market) }

    func dayChange(using market: MarketStore) -> Double {
        state.holdings.reduce(0) { total, holding in
            guard let quote = market.quote(holding.symbol) else { return total }
            return total + holding.quantity * quote.change
        }
    }

    /// Price a market order would fill at, before fees.
    func fillPrice(side: OrderSide, quote: Quote) -> Double {
        side == .buy ? quote.ask : quote.bid
    }

    @discardableResult
    func placeMarketOrder(symbol: String, side: OrderSide, quantity: Double, quote: Quote?, now: Date = Date()) throws -> Order {
        guard quantity > 0, quantity.rounded() == quantity else { throw OrderError.invalidQuantity }
        guard let quote else { throw OrderError.marketUnavailable }
        let price = fillPrice(side: side, quote: quote)
        let notional = price * quantity
        let fees = FeeSchedule.fees(for: notional)

        switch side {
        case .buy:
            guard notional + fees <= state.cash + 0.0001 else { throw OrderError.insufficientCash(needed: notional + fees) }
            state.cash -= notional + fees
            if let index = state.holdings.firstIndex(where: { $0.symbol == symbol }) {
                var holding = state.holdings[index]
                let cost = holding.costBasis + notional + fees
                holding.quantity += quantity
                holding.averageCost = cost / holding.quantity
                state.holdings[index] = holding
            } else {
                state.holdings.append(Holding(symbol: symbol, quantity: quantity, averageCost: (notional + fees) / quantity))
            }
        case .sell:
            guard let index = state.holdings.firstIndex(where: { $0.symbol == symbol }),
                  state.holdings[index].quantity >= quantity else {
                throw OrderError.insufficientShares(held: holding(symbol)?.quantity ?? 0)
            }
            state.cash += notional - fees
            state.holdings[index].quantity -= quantity
            if state.holdings[index].quantity <= 0 { state.holdings.remove(at: index) }
        }

        let order = Order(id: UUID(), symbol: symbol, side: side, type: .market, quantity: quantity, limitPrice: nil,
                          createdAt: now, status: .filled, fillPrice: price, fees: fees, filledAt: now, note: nil)
        state.orders.insert(order, at: 0)
        save()
        return order
    }

    func reset() {
        state = .fresh
        save()
    }

    /// Seeds a few positions so the Portfolio screen has content (used for screenshots).
    func seedDemo(using market: MarketStore) {
        reset()
        for (symbol, quantity) in [("COMI", 600.0), ("TMGH", 700.0), ("ETEL", 900.0), ("SWDY", 350.0), ("ABUK", 400.0)] {
            _ = try? placeMarketOrder(symbol: symbol, side: .buy, quantity: quantity, quote: market.quote(symbol))
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: Self.key) }
    }
}
