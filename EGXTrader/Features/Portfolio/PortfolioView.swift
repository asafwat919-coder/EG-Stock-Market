import SwiftUI
import Charts

struct PortfolioView: View {
    @Environment(MarketStore.self) private var market
    @Environment(PortfolioStore.self) private var portfolio
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Portfolio")
                        .font(.serif(32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    ValueHeroCard()
                    if portfolio.holdings.isEmpty {
                        emptyState
                    } else {
                        AllocationCard()
                        holdingsSection
                    }
                    if !portfolio.orders.isEmpty { ordersSection }
                    Button("Reset paper account", role: .destructive) { confirmReset = true }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Wordmark() } }
            .navigationDestination(for: Stock.self) { StockDetailView(stock: $0) }
            .confirmationDialog("Reset your paper account?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset to \(Fmt.egp(PortfolioState.initialCapital))", role: .destructive) {
                    withAnimation(.snappy) { portfolio.reset() }
                }
            } message: {
                Text("All holdings and order history will be cleared.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.goldGradient)
            Text("Start building your portfolio")
                .font(.serif(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("You have \(Fmt.egp(portfolio.cash)) of virtual cash. Open any stock in Markets and tap Buy.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Holdings", overline: "\(portfolio.holdings.count) positions")
            VStack(spacing: 0) {
                let holdings = portfolio.holdings
                ForEach(holdings) { holding in
                    if let stock = market.stock(holding.symbol) {
                        NavigationLink(value: stock) { HoldingRow(stock: stock, holding: holding) }
                            .buttonStyle(PressableStyle())
                        if holding.id != holdings.last?.id { RowDivider() }
                    }
                }
            }
            .cardStyle(padding: 14)
        }
    }

    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Activity", overline: "Orders")
            VStack(spacing: 0) {
                let orders = Array(portfolio.orders.prefix(8))
                ForEach(orders) { order in
                    HStack(spacing: 12) {
                        Image(systemName: order.side == .buy ? "arrow.down.left" : "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(order.side == .buy ? Theme.positive : Theme.negative)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill((order.side == .buy ? Theme.positive : Theme.negative).opacity(0.14)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(order.side.title) \(order.symbol)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(Fmt.integer(order.quantity)) @ \(Fmt.price(order.fillPrice ?? 0)) · \(Fmt.dateTime(order.createdAt))")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(Fmt.egp(order.notional))
                            .font(.numeric(14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.vertical, 10)
                    if order.id != orders.last?.id { RowDivider(inset: 46) }
                }
            }
            .cardStyle(padding: 14)
        }
    }
}

private struct ValueHeroCard: View {
    @Environment(MarketStore.self) private var market
    @Environment(PortfolioStore.self) private var portfolio

    var body: some View {
        let total = portfolio.totalValue(using: market)
        let invested = portfolio.marketValue(using: market)
        let day = portfolio.dayChange(using: market)
        let dayPercent = (total - day) == 0 ? 0 : day / (total - day) * 100
        let allTime = total - portfolio.state.startingCapital
        let allTimePercent = allTime / portfolio.state.startingCapital * 100

        VStack(alignment: .leading, spacing: 16) {
            Text("TOTAL VALUE").font(.overline).tracking(1.4).foregroundStyle(Theme.gold)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("EGP").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                Text(Fmt.price(total))
                    .font(.numeric(38, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: total))
                    .animation(.snappy, value: total)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                ChangePill(percent: dayPercent, style: .solid, size: 12.5)
                Text("\(Fmt.change(day)) today")
                    .font(.numeric(13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            HStack(spacing: 0) {
                metric("Cash", Fmt.compact(portfolio.cash), .white)
                metric("Invested", Fmt.compact(invested), .white)
                metric("All-time", Fmt.percent(allTimePercent), Theme.trend(allTime))
            }
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x14284D), Color(hex: 0x0A1428), Color(hex: 0x070C18)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .fill(RadialGradient(colors: [Color(hex: 0xD9B44A, alpha: 0.26), .clear],
                                         center: .topTrailing, startRadius: 0, endRadius: 240))
                RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Color(hex: 0xF3D98B, alpha: 0.5), .white.opacity(0.04)],
                                                 startPoint: .topTrailing, endPoint: .bottomLeading), lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x0A1428, alpha: 0.45), radius: 24, y: 14)
        }
        .environment(\.colorScheme, .dark)
    }

    private func metric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(.overline).tracking(0.8).foregroundStyle(.white.opacity(0.45))
            Text(value).font(.numeric(15, weight: .bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AllocationCard: View {
    @Environment(MarketStore.self) private var market
    @Environment(PortfolioStore.self) private var portfolio

    private struct Slice: Identifiable {
        let id: String
        let value: Double
        let color: Color
    }

    var body: some View {
        let slices = makeSlices()
        let total = max(slices.reduce(0) { $0 + $1.value }, 1)
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Allocation")
            HStack(spacing: 20) {
                Chart(slices) { slice in
                    SectorMark(angle: .value("Value", slice.value), innerRadius: .ratio(0.68), angularInset: 1.5)
                        .foregroundStyle(slice.color)
                        .cornerRadius(4)
                }
                .chartLegend(.hidden)
                .frame(width: 128, height: 128)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(slices) { slice in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3).fill(slice.color).frame(width: 10, height: 10)
                            Text(slice.id).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(Fmt.percent(slice.value / total * 100, signed: false))
                                .font(.numeric(12.5, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func makeSlices() -> [Slice] {
        var slices = portfolio.holdings.compactMap { holding -> Slice? in
            guard let stock = market.stock(holding.symbol) else { return nil }
            let value = holding.quantity * (market.quote(holding.symbol)?.price ?? holding.averageCost)
            return Slice(id: holding.symbol, value: value, color: stock.sector.colors[0])
        }
        .sorted { $0.value > $1.value }
        slices.append(Slice(id: "Cash", value: portfolio.cash, color: Theme.textTertiary))
        return slices
    }
}

private struct HoldingRow: View {
    @Environment(MarketStore.self) private var market
    let stock: Stock
    let holding: Holding

    var body: some View {
        let price = market.quote(stock.symbol)?.price ?? holding.averageCost
        let value = holding.quantity * price
        let gain = value - holding.costBasis
        let gainPercent = holding.costBasis == 0 ? 0 : gain / holding.costBasis * 100
        HStack(spacing: 12) {
            StockAvatar(stock: stock)
            VStack(alignment: .leading, spacing: 3) {
                Text(stock.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text("\(Fmt.integer(holding.quantity)) sh · avg \(Fmt.price(holding.averageCost))")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                FlashingPrice(price: value, font: .numeric(15.5))
                Text("\(Fmt.change(gain)) (\(Fmt.percent(gainPercent)))")
                    .font(.numeric(12, weight: .semibold))
                    .foregroundStyle(Theme.trend(gain))
            }
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}
