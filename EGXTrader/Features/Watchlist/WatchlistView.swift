import SwiftUI

struct WatchlistView: View {
    @Environment(MarketStore.self) private var market
    @Environment(WatchlistStore.self) private var watchlist

    var body: some View {
        NavigationStack {
            Group {
                if watchlist.symbols.isEmpty {
                    ContentUnavailableView(
                        "Your watchlist is empty",
                        systemImage: "star",
                        description: Text("Tap the star on any stock to follow it here.")
                    )
                } else {
                    List {
                        ForEach(watchlist.symbols, id: \.self) { symbol in
                            if let stock = market.stock(symbol) {
                                NavigationLink(value: stock) { StockRow(stock: stock) }
                                    .listRowBackground(Theme.surface)
                            }
                        }
                        .onDelete { watchlist.remove(atOffsets: $0) }
                        .onMove { watchlist.move(fromOffsets: $0, toOffset: $1) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Watchlist")
            .toolbar {
                if !watchlist.symbols.isEmpty { EditButton() }
            }
            .navigationDestination(for: Stock.self) { StockDetailView(stock: $0) }
        }
    }
}
