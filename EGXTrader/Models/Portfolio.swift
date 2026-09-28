import Foundation

enum OrderSide: String, Codable, CaseIterable, Identifiable {
    case buy, sell
    var id: String { rawValue }
    var title: String { self == .buy ? "Buy" : "Sell" }
}

enum OrderType: String, Codable, CaseIterable, Identifiable {
    case market, limit
    var id: String { rawValue }
    var title: String { self == .market ? "Market" : "Limit" }
}

enum OrderStatus: String, Codable {
    case pending, filled, cancelled, rejected

    var title: String { rawValue.capitalized }
}

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let quantity: Double
    let limitPrice: Double?
    let createdAt: Date
    var status: OrderStatus
    var fillPrice: Double?
    var fees: Double
    var filledAt: Date?
    var note: String?

    var notional: Double { quantity * (fillPrice ?? limitPrice ?? 0) }
}

struct Holding: Identifiable, Codable, Hashable {
    let symbol: String
    var quantity: Double
    /// Average cost per share including fees.
    var averageCost: Double

    var id: String { symbol }
    var costBasis: Double { quantity * averageCost }
}

struct PortfolioState: Codable {
    var cash: Double
    var holdings: [Holding]
    var orders: [Order]
    var startingCapital: Double

    static let initialCapital: Double = 250_000

    static var fresh: PortfolioState {
        PortfolioState(cash: initialCapital, holdings: [], orders: [], startingCapital: initialCapital)
    }
}

/// Indicative Egyptian brokerage cost model. Rates differ between brokers; this
/// captures the typical components so users see realistic all-in costs.
enum FeeSchedule {
    /// Broker commission.
    static let commissionRate = 0.0015
    /// EGX, MCDR, FRA and investor-protection fund fees combined.
    static let regulatoryRate = 0.00035
    static let minimumCommission = 5.0

    static func fees(for notional: Double) -> Double {
        guard notional > 0 else { return 0 }
        let commission = max(minimumCommission, notional * commissionRate)
        return commission + notional * regulatoryRate
    }
}
