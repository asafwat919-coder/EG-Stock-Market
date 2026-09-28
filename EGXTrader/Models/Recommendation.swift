import SwiftUI

enum Signal: String, CaseIterable, Identifiable, Codable {
    case strongBuy, buy, hold, sell, strongSell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strongBuy: return "Strong Buy"
        case .buy: return "Buy"
        case .hold: return "Hold"
        case .sell: return "Sell"
        case .strongSell: return "Strong Sell"
        }
    }

    var shortTitle: String {
        switch self {
        case .strongBuy: return "STRONG BUY"
        case .buy: return "BUY"
        case .hold: return "HOLD"
        case .sell: return "SELL"
        case .strongSell: return "STRONG SELL"
        }
    }

    var color: Color {
        switch self {
        case .strongBuy, .buy: return Theme.positive
        case .hold: return Theme.warning
        case .sell, .strongSell: return Theme.negative
        }
    }

    var symbolName: String {
        switch self {
        case .strongBuy: return "arrow.up.forward.circle.fill"
        case .buy: return "arrow.up.right.circle.fill"
        case .hold: return "pause.circle.fill"
        case .sell: return "arrow.down.right.circle.fill"
        case .strongSell: return "arrow.down.forward.circle.fill"
        }
    }

    var isBullish: Bool { self == .buy || self == .strongBuy }
    var isBearish: Bool { self == .sell || self == .strongSell }

    static func from(score: Double) -> Signal {
        switch score {
        case 45...: return .strongBuy
        case 15..<45: return .buy
        case -15..<15: return .hold
        case -45 ..< -15: return .sell
        default: return .strongSell
        }
    }
}

/// One input to the recommendation score, shown to the user as an explanation.
struct Factor: Identifiable, Hashable {
    enum Category: String {
        case trend = "Trend"
        case momentum = "Momentum"
        case meanReversion = "Mean Reversion"
        case volume = "Volume"
        case valuation = "Valuation"
        case risk = "Risk"
    }

    let name: String
    let category: Category
    let detail: String
    /// Contribution to the overall score, in points (negative = bearish).
    let impact: Double

    var id: String { name }
}

struct Recommendation: Identifiable, Hashable {
    let symbol: String
    let signal: Signal
    /// Composite score from -100 (very bearish) to +100 (very bullish).
    let score: Double
    /// 0...1 agreement between independent factors.
    let confidence: Double
    let price: Double
    let targetPrice: Double
    let stopLoss: Double
    let horizon: String
    let factors: [Factor]
    let summary: String
    let generatedAt: Date

    var id: String { symbol }
    var upside: Double { price == 0 ? 0 : (targetPrice - price) / price * 100 }
    var riskReward: Double {
        let risk = abs(price - stopLoss)
        return risk == 0 ? 0 : abs(targetPrice - price) / risk
    }
}

enum RiskProfile: String, CaseIterable, Identifiable, Codable {
    case conservative, balanced, aggressive

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var subtitle: String {
        switch self {
        case .conservative: return "Capital preservation, dividends, low volatility"
        case .balanced: return "Blend of growth and stability"
        case .aggressive: return "Maximise growth, tolerate large swings"
        }
    }

    var symbolName: String {
        switch self {
        case .conservative: return "shield.lefthalf.filled"
        case .balanced: return "scale.3d"
        case .aggressive: return "flame.fill"
        }
    }
}
