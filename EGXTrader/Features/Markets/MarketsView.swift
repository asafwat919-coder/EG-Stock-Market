import SwiftUI

struct MarketsView: View {
    @Environment(MarketStore.self) private var market
    @State private var moverKind: MarketStore.MoverKind = .gainers
    @State private var search = ""
    @State private var path: [Stock] = LaunchOptions.initialSymbol.flatMap { EGXUniverse.bySymbol[$0] }.map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    if search.isEmpty {
                        SessionHeader()
                        IndexCarousel()
                        BreadthCard()
                        moversSection
                        sectorsSection
                    }
                    allStocksSection
                    if market.isSimulated { SimulatedDataNotice() }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Markets")
            .searchable(text: $search, prompt: "Search EGX stocks")
            .navigationDestination(for: Stock.self) { StockDetailView(stock: $0) }
        }
    }

    private var moversSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Top Movers")
            Picker("Movers", selection: $moverKind) {
                ForEach(MarketStore.MoverKind.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Card {
                VStack(spacing: 0) {
                    let movers = market.movers(moverKind)
                    ForEach(movers) { stock in
                        NavigationLink(value: stock) { StockRow(stock: stock) }
                            .buttonStyle(.plain)
                        if stock.id != movers.last?.id { Divider().overlay(Theme.stroke) }
                    }
                }
            }
        }
    }

    private var sectorsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Sectors")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible())],
                      spacing: Theme.Spacing.m) {
                ForEach(market.sectors) { item in
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: item.sector.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(item.sector.colors[0])
                            .frame(width: 22)
                        Text(item.sector.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 2)
                        Text(Fmt.percent(item.changePercent))
                            .font(.numeric(13))
                            .foregroundStyle(Theme.trend(item.changePercent))
                    }
                    .padding(Theme.Spacing.m)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.small).fill(Theme.surface))
                }
            }
        }
    }

    private var filteredStocks: [Stock] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return market.stocks }
        return market.stocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
                || $0.nameAr.contains(query)
        }
    }

    private var allStocksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: search.isEmpty ? "All Stocks" : "Results", subtitle: "\(filteredStocks.count) listed")
            Card {
                VStack(spacing: 0) {
                    let stocks = filteredStocks
                    if stocks.isEmpty {
                        Text("No stocks match \u{201C}\(search)\u{201D}.")
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.l)
                    }
                    ForEach(stocks) { stock in
                        NavigationLink(value: stock) { StockRow(stock: stock) }
                            .buttonStyle(.plain)
                        if stock.id != stocks.last?.id { Divider().overlay(Theme.stroke) }
                    }
                }
            }
        }
    }
}

// MARK: - Session header

private struct SessionHeader: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Circle()
                .fill(market.session.isTrading ? Theme.positive : Theme.textTertiary)
                .frame(width: 8, height: 8)
            Text(market.session.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("·").foregroundStyle(Theme.textTertiary)
            Text(market.statusDetail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("Cairo " + Fmt.time(market.lastUpdated))
                .font(.numeric(12, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.top, Theme.Spacing.s)
    }
}

// MARK: - Indices

private struct IndexCarousel: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.m) {
                ForEach(market.indices) { index in
                    IndexCard(index: index, highlighted: index.code == "EGX30")
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
    }
}

private struct IndexCard: View {
    let index: MarketIndex
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(index.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(highlighted ? Theme.gold : Theme.textSecondary)
                Spacer()
                ChangeBadge(percent: index.changePercent, filled: false)
            }
            Text(Fmt.price(index.value))
                .font(.numeric(26, weight: .bold))
                .foregroundStyle(highlighted ? .white : Theme.textPrimary)
                .contentTransition(.numericText())
            Text(Fmt.change(index.change) + " pts")
                .font(.numeric(12, weight: .medium))
                .foregroundStyle(Theme.trend(index.change))
            Sparkline(values: index.intraday, color: Theme.trend(index.change), baseline: index.previousClose)
                .frame(height: 44)
        }
        .padding(Theme.Spacing.l)
        .frame(width: 230)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(highlighted ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                        .strokeBorder(highlighted ? Theme.gold.opacity(0.35) : Theme.stroke)
                )
        }
    }
}

// MARK: - Breadth

private struct BreadthCard: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        let breadth = market.breadth
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    Text("Market Breadth")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Turnover EGP " + Fmt.compact(market.totalTurnover))
                        .font(.numeric(12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                GeometryReader { proxy in
                    let total = Double(breadth.total)
                    HStack(spacing: 3) {
                        Capsule().fill(Theme.positive)
                            .frame(width: max(0, proxy.size.width * Double(breadth.advancers) / total - 2))
                        Capsule().fill(Theme.neutral)
                            .frame(width: max(0, proxy.size.width * Double(breadth.unchanged) / total - 2))
                        Capsule().fill(Theme.negative)
                    }
                }
                .frame(height: 8)
                HStack {
                    legend("Advancing", breadth.advancers, Theme.positive)
                    Spacer()
                    legend("Unchanged", breadth.unchanged, Theme.neutral)
                    Spacer()
                    legend("Declining", breadth.decliners, Theme.negative)
                }
            }
        }
    }

    private func legend(_ title: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(count)").font(.numeric(13)).foregroundStyle(Theme.textPrimary)
            Text(title).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }
}
