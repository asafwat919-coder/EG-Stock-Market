import Foundation
import Observation
import SwiftUI // for MutableCollection.move(fromOffsets:toOffset:)

/// The user's watchlist, persisted in `UserDefaults`.
@Observable
final class WatchlistStore {
    private(set) var symbols: [String]

    private let defaults: UserDefaults
    private static let key = "watchlist.symbols"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        symbols = defaults.stringArray(forKey: Self.key) ?? EGXUniverse.defaultWatchlist
    }

    func contains(_ symbol: String) -> Bool { symbols.contains(symbol) }

    func toggle(_ symbol: String) {
        if let index = symbols.firstIndex(of: symbol) {
            symbols.remove(at: index)
        } else {
            symbols.append(symbol)
        }
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) { symbols.remove(at: index) }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        symbols.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        defaults.set(symbols, forKey: Self.key)
    }
}
