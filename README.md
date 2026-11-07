# Nile Trader (EGX Trader)

iOS app for trading on the Egyptian Exchange (EGX) with AI buy/hold/sell recommendations.
SwiftUI, iOS 17+. Status: **work in progress**.

## Building without a Mac

iOS apps can only be compiled on macOS, so this repo uses **GitHub-hosted Macs** instead of a local one:

1. Edit Swift code anywhere (GitHub web editor, VS Code, Claude Code on the web).
2. Push. The **iOS build** workflow (`.github/workflows/ios.yml`) generates the Xcode project with
   [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`, compiles the app, runs the unit
   tests in the iOS Simulator and captures screenshots.
3. Open the run under the repo's **Actions** tab and download:
   - `screenshots`: PNGs of Markets, Stock Detail and Watchlist in dark and light mode
   - `EGXTrader-simulator-app`: the Simulator build. Upload it to [Appetize.io](https://appetize.io) to click
     through the real app in a browser.

macOS runners use GitHub Actions minutes at 10x the Linux rate on private repos (the free plan's
2,000 minutes cover roughly 200 macOS minutes, about 15–25 builds a month). Public repos are free.

### Install on your iPhone (TestFlight)

Needs a paid Apple Developer Program membership (USD 99/year). Everything else happens in the browser:

1. In [Certificates, IDs & Profiles](https://developer.apple.com/account/resources/identifiers/list) register the
   App ID `com.niletrader.app` (or change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to one you own).
2. In [App Store Connect](https://appstoreconnect.apple.com) create a new app with that bundle ID.
3. In App Store Connect > Users and Access > Integrations > App Store Connect API, create a key with the
   **Admin** role (needed for cloud-managed signing) and download the `.p8` file.
4. Add these repository secrets (Settings > Secrets and variables > Actions):

   | Secret | Value |
   | --- | --- |
   | `APP_STORE_CONNECT_KEY_ID` | Key ID shown next to the key |
   | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID shown above the keys list |
   | `APP_STORE_CONNECT_KEY_P8` | Full contents of the `.p8` file, including the BEGIN/END lines |
   | `APPLE_TEAM_ID` | 10-character Team ID from [Membership details](https://developer.apple.com/account) |

5. Actions > **TestFlight** > Run workflow. After Apple processes the build, install the TestFlight app on
   your iPhone and add yourself as an internal tester.

## What's here

| Path | Contents |
| --- | --- |
| `project.yml` | XcodeGen spec (app + unit test targets, iOS 17+, Info.plist keys) |
| `EGXTrader/App/` | App entry point, tab bar, screenshot launch options |
| `EGXTrader/Stores/` | `@Observable` MarketStore (live ticks, indices, breadth, movers, sectors) and WatchlistStore |
| `EGXTrader/Features/` | Markets, Stock Detail (Swift Charts, key stats), Watchlist, shared components |
| `EGXTrader/DesignSystem/` | Colors, typography and number/date formatters (dark ink + gold theme, light mode too) |
| `EGXTrader/Models/` | Stocks, quotes, candles, indices, orders, holdings, fee schedule, AI recommendation types |
| `EGXTrader/Data/` | EGX universe (30 companies), Cairo trading calendar (Sun–Thu, 10:00–14:30), seeded RNG, simulated market feed |
| `EGXTrader/Resources/` | Asset catalog (app icon, accent and launch colors) |
| `EGXTraderTests/` | Unit tests: market clock, fees, signals, feed determinism and price limits |
| `scripts/` | Simulator picker and screenshot script used by CI |
| `preview/nile-trader.html` | Browser preview of the full app design (all screens, live ticks, AI engine, paper trading, analyst chat) |

Live preview: https://claude.ai/artifact/DJXvDLeVuwgxRuweJgd53e (private to the owner)

## Still to do (iOS)

1. `AI/` – technical indicators + recommendation engine (port from the JS in the preview), Claude API client for the AI Analyst chat (raw HTTP streaming, API key in Keychain)
2. `Stores/` – PortfolioStore, SettingsStore
3. `Features/` – AI Insights + chat, Order Ticket (Face ID confirm), Portfolio, Profile, Onboarding

## Notes

- Prices are **simulated** around indicative levels, not live EGX quotes. A licensed data vendor can be plugged in via the `MarketFeed` protocol.
- Not affiliated with the Egyptian Exchange. AI ratings are educational, not investment advice.
