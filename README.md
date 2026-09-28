# Nile Trader (EGX Trader)

iOS app for trading on the Egyptian Exchange (EGX) with AI buy/hold/sell recommendations.
SwiftUI, iOS 17+. Status: **work in progress**.

## What's here

| Path | Contents |
| --- | --- |
| `EGXTrader/DesignSystem/` | Colors, typography and number/date formatters (dark ink + gold theme, light mode too) |
| `EGXTrader/Models/` | Stocks, quotes, candles, indices, orders, holdings, fee schedule, AI recommendation types |
| `EGXTrader/Data/` | EGX universe (30 companies), Cairo trading calendar (Sun–Thu, 10:00–14:30), seeded RNG, simulated market feed |
| `preview/nile-trader.html` | Working browser preview of the full app design (all screens, live ticks, AI engine, paper trading, analyst chat) |

Live preview: https://claude.ai/artifact/DJXvDLeVuwgxRuweJgd53e (private to the owner)

To view the preview locally, open `preview/nile-trader.html` in a browser.

## Still to do (iOS)

1. `AI/` – technical indicators + recommendation engine (port from the JS in the preview), Claude API client for the AI Analyst chat (raw HTTP streaming, model `claude-opus-5-5`, API key in Keychain)
2. `Stores/` – `@Observable` MarketStore, PortfolioStore, WatchlistStore, SettingsStore
3. `Features/` – Markets, Stock Detail (Swift Charts), Order Ticket (Face ID confirm), Watchlist, AI Insights + chat, Portfolio, Profile, Onboarding
4. `App/` entry point, asset catalog, `EGXTrader.xcodeproj` (Xcode 16 synchronized folders), unit tests

## Notes

- Prices are **simulated** around indicative levels, not live EGX quotes. A licensed data vendor can be plugged in via the `MarketFeed` protocol.
- Not affiliated with the Egyptian Exchange. AI ratings are educational, not investment advice.
