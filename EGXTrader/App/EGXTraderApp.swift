import SwiftUI

@main
struct EGXTraderApp: App {
    @State private var market = MarketStore()
    @State private var watchlist = WatchlistStore()
    @State private var portfolio = PortfolioStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(market)
                .environment(watchlist)
                .environment(portfolio)
                .tint(Theme.gold)
                .onAppear {
                    if LaunchOptions.demoPortfolio { portfolio.seedDemo(using: market) }
                }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { market.start() } else { market.stop() }
        }
    }
}

struct RootView: View {
    enum Tab: Hashable { case markets, watchlist, insights, portfolio }

    @State private var selection: Tab = LaunchOptions.initialTab

    var body: some View {
        TabView(selection: $selection) {
            MarketsView()
                .tabItem { Label("Markets", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.markets)
            WatchlistView()
                .tabItem { Label("Watchlist", systemImage: "star.fill") }
                .tag(Tab.watchlist)
            InsightsTeaserView()
                .tabItem { Label("Insights", systemImage: "sparkles") }
                .tag(Tab.insights)
            PortfolioView()
                .tabItem { Label("Portfolio", systemImage: "chart.pie.fill") }
                .tag(Tab.portfolio)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Launch arguments used by CI to open a specific screen for screenshots, e.g.
/// `xcrun simctl launch <device> com.niletrader.app -screenshotTab watchlist -screenshotSymbol COMI`.
enum LaunchOptions {
    static var initialTab: RootView.Tab {
        switch UserDefaults.standard.string(forKey: "screenshotTab") {
        case "watchlist": return .watchlist
        case "insights": return .insights
        case "portfolio": return .portfolio
        default: return .markets
        }
    }

    static var initialSymbol: String? {
        UserDefaults.standard.string(forKey: "screenshotSymbol")
    }

    static var initialTicket: OrderSide? {
        UserDefaults.standard.string(forKey: "screenshotTicket").flatMap(OrderSide.init(rawValue:))
    }

    static var scrollTarget: String? {
        UserDefaults.standard.string(forKey: "screenshotScroll")
    }

    static var demoPortfolio: Bool {
        UserDefaults.standard.bool(forKey: "demoPortfolio")
    }
}
