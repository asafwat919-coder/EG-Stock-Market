import SwiftUI
import Charts

struct MarketsView: View {
    @Environment(MarketStore.self) private var market
    @State private var search = ""
    @State private var path: [Stock] = LaunchOptions.initialSymbol.flatMap { EGXUniverse.bySymbol[$0] }.map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        if search.isEmpty {
                            GreetingHeader()
                            HeroIndexCard()
                            MarketPulse().id("pulse")
                            MoversSection().id("movers")
                            SectorHeatmap().id("sectors")
                        }
                        StockListSection(search: search).id("stocks")
                        if market.isSimulated { SimulatedDataNotice() }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.s)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .task {
                    guard let target = LaunchOptions.scrollTarget else { return }
                    try? await Task.sleep(for: .milliseconds(600))
                    proxy.scrollTo(target, anchor: .top)
                }
            }
            .scrollIndicators(.hidden)
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark() }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search 30 EGX stocks")
            .navigationDestination(for: Stock.self) { StockDetailView(stock: $0) }
        }
    }
}

struct Wordmark: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "triangle.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.goldGradient)
            Text("NILE TRADER")
                .font(.system(size: 13, weight: .bold).width(.expanded))
                .tracking(2.2)
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel("Nile Trader")
    }
}

// MARK: - Header

private struct GreetingHeader: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(greeting)
                .font(.serif(32, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 8) {
                LiveDot(active: market.session.isTrading)
                Text(market.session.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(market.session.isTrading ? Theme.positive : Theme.textSecondary)
                Text("·").foregroundStyle(Theme.textTertiary)
                Text(market.statusDetail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Label(Fmt.time(market.lastUpdated), systemImage: "clock")
                    .font(.numeric(12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .labelStyle(.titleAndIcon)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Capsule(style: .continuous).fill(Theme.surface.opacity(0.8)))
            .overlay(Capsule(style: .continuous).strokeBorder(Theme.stroke))
        }
    }

    private var greeting: String {
        let hour = MarketClock.calendar.component(.hour, from: market.lastUpdated)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Hero index

private struct HeroIndexCard: View {
    @Environment(MarketStore.self) private var market
    @State private var code = "EGX30"

    var body: some View {
        let index = market.indices.first { $0.code == code } ?? market.indices.first
        VStack(alignment: .leading, spacing: 14) {
            if let index {
                HStack {
                    Text(index.name.uppercased())
                        .font(.overline)
                        .tracking(1.4)
                        .foregroundStyle(Theme.gold)
                    Spacer()
                    Text("EGP · Cairo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Fmt.price(index.value))
                        .font(.numeric(40, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: index.value))
                        .animation(.snappy, value: index.value)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    ChangePill(percent: index.changePercent, style: .solid, size: 13)
                    Text(Fmt.change(index.change) + " pts today")
                        .font(.numeric(13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Sparkline(values: index.intraday, color: Theme.trend(index.change), baseline: index.previousClose,
                          filled: true, lineWidth: 2.2, samples: 90)
                    .frame(height: 120)
                    .padding(.horizontal, -4)
                HStack {
                    Text("10:00").font(.numeric(11, weight: .medium))
                    Spacer()
                    Text("12:15").font(.numeric(11, weight: .medium))
                    Spacer()
                    Text("14:30").font(.numeric(11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.35))
            }
            HStack(spacing: 8) {
                ForEach(market.indices) { item in
                    Button {
                        withAnimation(.snappy) { code = item.code }
                    } label: {
                        VStack(spacing: 3) {
                            Text(item.code)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(item.code == code ? Theme.onGold : .white.opacity(0.85))
                            Text(Fmt.percent(item.changePercent))
                                .font(.numeric(11, weight: .semibold))
                                .foregroundStyle(item.code == code ? Theme.onGold.opacity(0.8) : Theme.trend(item.changePercent))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(item.code == code ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.07)))
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .sensoryFeedback(.selection, trigger: code)
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x14284D), Color(hex: 0x0A1428), Color(hex: 0x070C18)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .fill(RadialGradient(colors: [Color(hex: 0xD9B44A, alpha: 0.28), .clear],
                                         center: .topTrailing, startRadius: 0, endRadius: 260))
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Color(hex: 0xF3D98B, alpha: 0.55), .white.opacity(0.05)],
                                                 startPoint: .topTrailing, endPoint: .bottomLeading), lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x0A1428, alpha: 0.45), radius: 24, y: 14)
        }
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Market pulse

private struct MarketPulse: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        let breadth = market.breadth
        let ratio = Double(breadth.advancers) / Double(max(breadth.advancers + breadth.decliners, 1))
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 10) {
                Text("BREADTH").font(.overline).tracking(1).foregroundStyle(Theme.textTertiary)
                ZStack {
                    Chart {
                        SectorMark(angle: .value("Up", breadth.advancers), innerRadius: .ratio(0.72), angularInset: 1.5)
                            .foregroundStyle(Theme.positive).cornerRadius(3)
                        SectorMark(angle: .value("Flat", breadth.unchanged), innerRadius: .ratio(0.72), angularInset: 1.5)
                            .foregroundStyle(Theme.neutral).cornerRadius(3)
                        SectorMark(angle: .value("Down", breadth.decliners), innerRadius: .ratio(0.72), angularInset: 1.5)
                            .foregroundStyle(Theme.negative).cornerRadius(3)
                    }
                    .chartLegend(.hidden)
                    VStack(spacing: 0) {
                        Text("\(breadth.advancers)")
                            .font(.numeric(22, weight: .bold))
                            .foregroundStyle(Theme.positive)
                            .contentTransition(.numericText(value: Double(breadth.advancers)))
                        Text("of \(breadth.total)")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(height: 104)
                .frame(maxWidth: .infinity)
                HStack(spacing: 10) {
                    dot(Theme.positive, breadth.advancers)
                    dot(Theme.neutral, breadth.unchanged)
                    dot(Theme.negative, breadth.decliners)
                }
                .frame(maxWidth: .infinity)
            }
            .cardStyle(padding: 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("TURNOVER").font(.overline).tracking(1).foregroundStyle(Theme.textTertiary)
                Text("EGP " + Fmt.compact(market.totalTurnover))
                    .font(.numeric(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText(value: market.totalTurnover))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text("SENTIMENT").font(.overline).tracking(1).foregroundStyle(Theme.textTertiary)
                Text(sentiment(ratio))
                    .font(.serif(19, weight: .bold))
                    .foregroundStyle(Theme.trend(ratio - 0.5))
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceMuted)
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.negative, Theme.warning, Theme.positive],
                                                 startPoint: .leading, endPoint: .trailing))
                            .mask(alignment: .leading) {
                                Capsule().frame(width: max(8, proxy.size.width * ratio))
                            }
                    }
                }
                .frame(height: 8)
                .animation(.snappy, value: ratio)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .cardStyle(padding: 14)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func dot(_ color: Color, _ value: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(value)").font(.numeric(11.5, weight: .semibold)).foregroundStyle(Theme.textSecondary)
        }
    }

    private func sentiment(_ ratio: Double) -> String {
        switch ratio {
        case 0.65...: return "Bullish"
        case 0.55..<0.65: return "Mildly bullish"
        case 0.45..<0.55: return "Neutral"
        case 0.35..<0.45: return "Mildly bearish"
        default: return "Bearish"
        }
    }
}

// MARK: - Movers

private struct MoversSection: View {
    @Environment(MarketStore.self) private var market
    @State private var kind: MarketStore.MoverKind = .gainers

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Top movers", overline: "Today")
            CapsuleSegmented(options: MarketStore.MoverKind.allCases, selection: $kind, label: \.rawValue, compact: true)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(market.movers(kind, limit: 6)) { stock in
                        NavigationLink(value: stock) { MoverCard(stock: stock) }
                            .buttonStyle(PressableStyle())
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

private struct MoverCard: View {
    @Environment(MarketStore.self) private var market
    let stock: Stock

    var body: some View {
        let quote = market.quote(stock.symbol)
        let change = quote?.changePercent ?? 0
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StockAvatar(stock: stock, size: 34)
                Spacer()
                ChangePill(percent: change, size: 11)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Sparkline(values: market.intraday(for: stock.symbol).map(\.price), color: Theme.trend(change),
                      baseline: quote?.previousClose, filled: true, lineWidth: 1.6, samples: 40)
                .frame(height: 38)
            FlashingPrice(price: quote?.price, font: .numeric(16, weight: .bold), prefix: "EGP ")
        }
        .frame(width: 152)
        .cardStyle(padding: 14, radius: Theme.Radius.medium + 2)
    }
}

// MARK: - Sector heatmap

private struct SectorHeatmap: View {
    @Environment(MarketStore.self) private var market

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sector heatmap", overline: "Rotation")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(market.sectors) { item in
                    let intensity = min(abs(item.changePercent) / 2.5, 1)
                    let color = Theme.trend(item.changePercent)
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: item.sector.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(intensity > 0.55 ? .white : color)
                        Spacer(minLength: 0)
                        Text(item.sector.displayName)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(intensity > 0.55 ? .white : Theme.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Text(Fmt.percent(item.changePercent))
                            .font(.numeric(14, weight: .bold))
                            .foregroundStyle(intensity > 0.55 ? .white : color)
                            .contentTransition(.numericText(value: item.changePercent))
                    }
                    .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
                    .padding(11)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(color.opacity(0.10 + 0.72 * intensity))
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(color.opacity(0.25))
                    }
                    .animation(.easeInOut(duration: 0.6), value: intensity)
                }
            }
        }
    }
}

// MARK: - All stocks

private struct StockListSection: View {
    enum Sort: String, CaseIterable, Identifiable {
        case symbol = "Symbol", change = "Change", turnover = "Turnover", marketCap = "Market cap"
        var id: String { rawValue }
    }

    @Environment(MarketStore.self) private var market
    let search: String
    @State private var sort: Sort = .marketCap

    var body: some View {
        let stocks = sorted(filtered)
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: search.isEmpty ? "All stocks" : "Results", overline: "\(stocks.count) listed") {
                Menu {
                    Picker("Sort by", selection: $sort) {
                        ForEach(Sort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label(sort.rawValue, systemImage: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.surfaceMuted))
                }
                .tint(Theme.textPrimary)
            }
            VStack(spacing: 0) {
                if stocks.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .padding(.vertical, Theme.Spacing.l)
                }
                ForEach(stocks) { stock in
                    NavigationLink(value: stock) { StockRow(stock: stock) }
                        .buttonStyle(PressableStyle())
                    if stock.id != stocks.last?.id { RowDivider() }
                }
            }
            .cardStyle(padding: 14)
        }
    }

    private var filtered: [Stock] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return market.stocks }
        return market.stocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
                || $0.nameAr.contains(query)
        }
    }

    private func sorted(_ stocks: [Stock]) -> [Stock] {
        switch sort {
        case .symbol:
            return stocks.sorted { $0.symbol < $1.symbol }
        case .change:
            return stocks.sorted { (market.quote($0.symbol)?.changePercent ?? 0) > (market.quote($1.symbol)?.changePercent ?? 0) }
        case .turnover:
            return stocks.sorted { (market.quote($0.symbol)?.turnover ?? 0) > (market.quote($1.symbol)?.turnover ?? 0) }
        case .marketCap:
            return stocks.sorted { capOf($0) > capOf($1) }
        }
    }

    private func capOf(_ stock: Stock) -> Double {
        stock.sharesOutstandingM * (market.quote(stock.symbol)?.price ?? stock.referencePrice)
    }
}
