import SwiftUI

struct WatchlistView: View {
    @Environment(MarketStore.self) private var market
    @Environment(WatchlistStore.self) private var watchlist

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summary
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                if watchlist.symbols.isEmpty {
                    ContentUnavailableView("Nothing here yet", systemImage: "star",
                                           description: Text("Tap the star on any stock to follow it."))
                        .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(watchlist.symbols, id: \.self) { symbol in
                            if let stock = market.stock(symbol) {
                                NavigationLink(value: stock) { StockRow(stock: stock) }
                                    .listRowBackground(Theme.surface)
                                    .listRowSeparatorTint(Theme.stroke)
                            }
                        }
                        .onDelete { watchlist.remove(atOffsets: $0) }
                        .onMove { watchlist.move(fromOffsets: $0, toOffset: $1) }
                    } header: {
                        Text("Following")
                            .font(.overline)
                            .tracking(1.2)
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Watchlist")
            .toolbar {
                if !watchlist.symbols.isEmpty { EditButton().tint(Theme.gold) }
            }
            .navigationDestination(for: Stock.self) { StockDetailView(stock: $0) }
        }
    }

    private var summary: some View {
        let quotes = watchlist.symbols.compactMap { market.quote($0) }
        let average = quotes.isEmpty ? 0 : quotes.reduce(0) { $0 + $1.changePercent } / Double(quotes.count)
        let up = quotes.filter { $0.change > 0 }.count
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AVG. MOVE").font(.overline).tracking(1).foregroundStyle(Theme.textTertiary)
                Text(Fmt.percent(average))
                    .font(.numeric(24, weight: .bold))
                    .foregroundStyle(Theme.trend(average))
                    .contentTransition(.numericText(value: average))
            }
            .cardStyle(padding: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text("ADVANCING").font(.overline).tracking(1).foregroundStyle(Theme.textTertiary)
                Text("\(up) of \(quotes.count)")
                    .font(.numeric(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .cardStyle(padding: 14)
        }
    }
}
