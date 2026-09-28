import Foundation

struct MarketIndex: Identifiable, Hashable {
    let code: String
    let name: String
    let baseValue: Double
    var value: Double
    var previousClose: Double
    /// Intraday path of the index value.
    var intraday: [Double]

    var id: String { code }
    var change: Double { value - previousClose }
    var changePercent: Double { previousClose == 0 ? 0 : change / previousClose * 100 }
}

enum MarketSession: Equatable {
    case preOpen
    case open
    case closingAuction
    case closed

    var title: String {
        switch self {
        case .preOpen: return "Pre-open"
        case .open: return "Market Open"
        case .closingAuction: return "Closing Auction"
        case .closed: return "Market Closed"
        }
    }

    var isTrading: Bool { self == .open || self == .closingAuction }
}

struct SectorPerformance: Identifiable, Hashable {
    let sector: Sector
    let changePercent: Double
    let turnover: Double
    let constituents: Int

    var id: Sector { sector }
}

struct MarketBreadth: Hashable {
    let advancers: Int
    let decliners: Int
    let unchanged: Int

    var total: Int { max(1, advancers + decliners + unchanged) }
}
