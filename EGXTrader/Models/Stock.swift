import Foundation
import SwiftUI

enum Sector: String, CaseIterable, Codable, Identifiable {
    case banks
    case nonBankFinancial
    case realEstate
    case basicResources
    case industrial
    case construction
    case telecomTech
    case foodBeverage
    case healthcare
    case consumer
    case energy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .banks: return "Banks"
        case .nonBankFinancial: return "Financial Services"
        case .realEstate: return "Real Estate"
        case .basicResources: return "Basic Resources"
        case .industrial: return "Industrial Goods"
        case .construction: return "Construction"
        case .telecomTech: return "Telecom & Tech"
        case .foodBeverage: return "Food & Beverage"
        case .healthcare: return "Healthcare"
        case .consumer: return "Consumer"
        case .energy: return "Energy"
        }
    }

    var symbolName: String {
        switch self {
        case .banks: return "building.columns.fill"
        case .nonBankFinancial: return "chart.line.uptrend.xyaxis"
        case .realEstate: return "building.2.fill"
        case .basicResources: return "cube.fill"
        case .industrial: return "gearshape.2.fill"
        case .construction: return "hammer.fill"
        case .telecomTech: return "antenna.radiowaves.left.and.right"
        case .foodBeverage: return "fork.knife"
        case .healthcare: return "cross.case.fill"
        case .consumer: return "bag.fill"
        case .energy: return "bolt.fill"
        }
    }

    /// Two-tone gradient used for company avatars in this sector.
    var colors: [Color] {
        switch self {
        case .banks: return [Color(hex: 0x2E6BE6), Color(hex: 0x173B8C)]
        case .nonBankFinancial: return [Color(hex: 0x7B5CFA), Color(hex: 0x3F2A9E)]
        case .realEstate: return [Color(hex: 0xE0A43A), Color(hex: 0x9A6512)]
        case .basicResources: return [Color(hex: 0x8C9BAE), Color(hex: 0x4A5566)]
        case .industrial: return [Color(hex: 0x14B8A6), Color(hex: 0x0B6E64)]
        case .construction: return [Color(hex: 0xF97316), Color(hex: 0x9A3A07)]
        case .telecomTech: return [Color(hex: 0x06B6D4), Color(hex: 0x0E5F8A)]
        case .foodBeverage: return [Color(hex: 0x22C55E), Color(hex: 0x15703A)]
        case .healthcare: return [Color(hex: 0xEF4444), Color(hex: 0x8F1D1D)]
        case .consumer: return [Color(hex: 0xEC4899), Color(hex: 0x8A1F58)]
        case .energy: return [Color(hex: 0xEAB308), Color(hex: 0x8A6A06)]
        }
    }
}

/// Static reference data for a company listed on the Egyptian Exchange.
struct Stock: Identifiable, Hashable, Codable {
    let symbol: String
    let name: String
    let nameAr: String
    let sector: Sector
    /// Shares outstanding, in millions.
    let sharesOutstandingM: Double
    /// Reference price (EGP) used to seed the simulated feed.
    let referencePrice: Double
    /// Typical daily volatility (standard deviation of daily returns).
    let dailyVolatility: Double
    let peRatio: Double
    let dividendYield: Double
    let isEGX30: Bool

    var id: String { symbol }

    var initials: String { String(symbol.prefix(2)) }
}

/// Live snapshot of a stock's trading session.
struct Quote: Hashable {
    let symbol: String
    var price: Double
    var previousClose: Double
    var open: Double
    var high: Double
    var low: Double
    /// Shares traded today.
    var volume: Double
    var bid: Double
    var ask: Double
    var updatedAt: Date
    /// Direction of the last tick; drives the price flash animation.
    var lastTick: Double = 0

    var change: Double { price - previousClose }
    var changePercent: Double { previousClose == 0 ? 0 : change / previousClose * 100 }
    /// Traded value today in EGP.
    var turnover: Double { volume * (high + low + price) / 3 }
    var spread: Double { ask - bid }
}

struct Candle: Identifiable, Hashable, Codable {
    let date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double

    var id: Date { date }
    var isBullish: Bool { close >= open }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case fiveYears = "5Y"

    var id: String { rawValue }

    /// Number of daily bars shown for this range (intraday handled separately).
    var tradingDays: Int {
        switch self {
        case .day: return 1
        case .week: return 5
        case .month: return 22
        case .threeMonths: return 66
        case .year: return 250
        case .fiveYears: return 1250
        }
    }
}

struct OrderBookLevel: Identifiable, Hashable {
    let id: Int
    let price: Double
    let quantity: Double
}
