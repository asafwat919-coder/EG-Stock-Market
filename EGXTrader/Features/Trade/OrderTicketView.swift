import SwiftUI

/// Market order ticket for paper trading: side, quantity with quick-fill
/// chips, an itemised cost estimate including EGX fees, and a confirmation.
struct OrderTicketView: View {
    @Environment(MarketStore.self) private var market
    @Environment(PortfolioStore.self) private var portfolio
    @Environment(\.dismiss) private var dismiss

    let stock: Stock
    @State private var side: OrderSide
    @State private var quantity: Double = 100
    @State private var filled: Order?
    @State private var errorMessage: String?

    init(stock: Stock, initialSide: OrderSide) {
        self.stock = stock
        _side = State(initialValue: initialSide)
    }

    var body: some View {
        let quote = market.quote(stock.symbol)
        let price = quote.map { portfolio.fillPrice(side: side, quote: $0) } ?? 0
        let notional = price * quantity
        let fees = FeeSchedule.fees(for: notional)
        let total = side == .buy ? notional + fees : notional - fees

        NavigationStack {
            ZStack {
                AppBackground()
                if let filled {
                    OrderConfirmation(order: filled, stock: stock) { dismiss() }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ticketHeader(quote)
                            CapsuleSegmented(options: OrderSide.allCases, selection: $side, label: \.title)
                            quantityCard(price: price)
                            estimateCard(price: price, notional: notional, fees: fees, total: total)
                            Text("Market order · fills immediately at the best \(side == .buy ? "ask" : "bid"). Paper trading with virtual funds.")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(Theme.Spacing.l)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Button {
                            place(quote: quote)
                        } label: {
                            Text("\(side.title) \(Fmt.integer(quantity)) \(stock.symbol) · \(Fmt.egp(total))")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .buttonStyle(PillButtonStyle(kind: side == .buy ? .gold : .negative))
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .disabled(quantity <= 0 || quote == nil)
                    }
                }
            }
            .navigationTitle(filled == nil ? "New order" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if filled == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
            }
            .alert("Order not placed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sensoryFeedback(.success, trigger: filled?.id)
            .sensoryFeedback(.error, trigger: errorMessage)
        }
    }

    private func ticketHeader(_ quote: Quote?) -> some View {
        HStack(spacing: 12) {
            StockAvatar(stock: stock, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text(stock.name).font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                FlashingPrice(price: quote?.price, font: .numeric(18, weight: .bold))
                ChangePill(percent: quote?.changePercent ?? 0, size: 11)
            }
        }
        .cardStyle()
    }

    private func quantityCard(price: Double) -> some View {
        let held = portfolio.holding(stock.symbol)?.quantity ?? 0
        let maxBuy = price > 0 ? floor(portfolio.cash / (price * (1 + FeeSchedule.commissionRate + FeeSchedule.regulatoryRate)) ) : 0
        let maximum = side == .buy ? max(maxBuy, 0) : held
        return VStack(spacing: 16) {
            Text("SHARES").font(.overline).tracking(1.2).foregroundStyle(Theme.textTertiary)
            HStack(spacing: 18) {
                stepButton("minus") { quantity = max(0, quantity - step) }
                Text(Fmt.integer(quantity))
                    .font(.numeric(44, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText(value: quantity))
                    .animation(.snappy, value: quantity)
                    .frame(minWidth: 140)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                stepButton("plus") { quantity += step }
            }
            HStack(spacing: 8) {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                    Button(fraction == 1 ? "Max" : "\(Int(fraction * 100))%") {
                        withAnimation(.snappy) { quantity = floor(maximum * fraction) }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Theme.surfaceMuted))
                    .buttonStyle(PressableStyle())
                    .disabled(maximum <= 0)
                }
            }
            Text(side == .buy ? "Buying power \(Fmt.egp(portfolio.cash))" : "You hold \(Fmt.integer(held)) shares")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .sensoryFeedback(.increase, trigger: quantity)
    }

    private var step: Double { quantity >= 1_000 ? 100 : quantity >= 100 ? 50 : 10 }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.snappy) { action() } }) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.surfaceMuted))
                .overlay(Circle().strokeBorder(Theme.stroke))
        }
        .buttonStyle(PressableStyle())
        .buttonRepeatBehavior(.enabled)
    }

    private func estimateCard(price: Double, notional: Double, fees: Double, total: Double) -> some View {
        VStack(spacing: 12) {
            line("Est. price", Fmt.egp(price))
            line("Order value", Fmt.egp(notional))
            line("Commission & EGX fees", Fmt.egp(fees))
            Rectangle().fill(Theme.stroke).frame(height: 1)
            HStack {
                Text(side == .buy ? "Total cost" : "You receive")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(Fmt.egp(total))
                    .font(.numeric(18, weight: .bold))
                    .contentTransition(.numericText(value: total))
            }
            .foregroundStyle(Theme.textPrimary)
        }
        .cardStyle()
    }

    private func line(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.numeric(14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
        }
        .font(.system(size: 14))
    }

    private func place(quote: Quote?) {
        do {
            let order = try portfolio.placeMarketOrder(symbol: stock.symbol, side: side, quantity: quantity, quote: quote)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { filled = order }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct OrderConfirmation: View {
    let order: Order
    let stock: Stock
    let done: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.goldSoft).frame(width: 132, height: 132)
                    .scaleEffect(appeared ? 1 : 0.6)
                Circle().fill(Theme.goldGradient).frame(width: 92, height: 92)
                    .shadow(color: Theme.gold.opacity(0.45), radius: 20, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.onGold)
                    .symbolEffect(.bounce, value: appeared)
            }
            VStack(spacing: 8) {
                Text("Order filled")
                    .font(.serif(30, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(order.side == .buy ? "Bought" : "Sold") \(Fmt.integer(order.quantity)) \(stock.symbol) at \(Fmt.egp(order.fillPrice ?? 0))")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Text("Fees \(Fmt.egp(order.fees)) · \(Fmt.dateTime(order.createdAt))")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button("Done", action: done)
                .buttonStyle(PillButtonStyle(kind: .gold))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true } }
    }
}
