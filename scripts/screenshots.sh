#!/usr/bin/env bash
# Installs the Simulator build and captures screenshots of the main screens in
# dark and light mode. Usage: scripts/screenshots.sh <simulator-udid> <path/to/App.app> <output-dir>
set -euo pipefail

UDID="$1"
APP="$2"
OUT="$3"
BUNDLE_ID="com.niletrader.app"
mkdir -p "$OUT"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "11:30" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 || true
xcrun simctl install "$UDID" "$APP"

shoot() { # name, appearance, launch args...
  local name="$1" appearance="$2"; shift 2
  xcrun simctl ui "$UDID" appearance "$appearance"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@" >/dev/null
  sleep 7 # let the feed tick a few times and charts animate in
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "captured $name"
}

shoot 01-markets-dark       dark  -screenshotTab markets
shoot 02-stock-detail-dark  dark  -screenshotTab markets -screenshotSymbol COMI -demoPortfolio YES
shoot 03-order-ticket-dark  dark  -screenshotTab markets -screenshotSymbol TMGH -screenshotTicket buy
shoot 04-portfolio-dark     dark  -screenshotTab portfolio -demoPortfolio YES
shoot 05-watchlist-dark     dark  -screenshotTab watchlist
shoot 06-insights-dark      dark  -screenshotTab insights
shoot 07-markets-light      light -screenshotTab markets
shoot 08-stock-detail-light light -screenshotTab markets -screenshotSymbol SWDY
shoot 09-portfolio-light    light -screenshotTab portfolio -demoPortfolio YES

# Scrolled views of the Markets screen (lower sections)
shoot 10-markets-movers-dark  dark -screenshotTab markets -screenshotScroll movers
shoot 11-markets-stocks-dark  dark -screenshotTab markets -screenshotScroll stocks
