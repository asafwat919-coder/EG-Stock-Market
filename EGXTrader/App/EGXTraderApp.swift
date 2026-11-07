import SwiftUI

@main
struct EGXTraderApp: App {
    @State private var market = MarketStore()
    @State private var watchlist = WatchlistStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(market)
                .environment(watchlist)
                .tint(Theme.gold)
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
            ComingSoonView(title: "AI Insights", systemImage: "sparkles",
                           detail: "Buy / hold / sell ratings with explained factors and the AI analyst chat.")
                .tabItem { Label("Insights", systemImage: "sparkles") }
                .tag(Tab.insights)
            ComingSoonView(title: "Portfolio", systemImage: "briefcase.fill",
                           detail: "Paper trading with EGP 250,000 virtual capital, realistic EGX fees and order history.")
                .tabItem { Label("Portfolio", systemImage: "briefcase.fill") }
                .tag(Tab.portfolio)
        }
    }
}

struct ComingSoonView: View {
    let title: String
    let systemImage: String
    let detail: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(detail))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationTitle(title)
        }
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
}
