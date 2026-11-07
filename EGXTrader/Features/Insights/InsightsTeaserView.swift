import SwiftUI

/// Placeholder for the AI Insights tab until the recommendation engine lands.
struct InsightsTeaserView: View {
    private let features: [(String, String, String)] = [
        ("gauge.with.dots.needle.67percent", "Buy / hold / sell ratings", "A score from −100 to +100 for every EGX stock, refreshed with the market."),
        ("list.bullet.rectangle.portrait", "Explained factors", "Trend, momentum, mean reversion, volume and valuation, each with its impact."),
        ("target", "Targets & stops", "Suggested target price, stop loss and risk/reward for your risk profile."),
        ("bubble.left.and.text.bubble.right.fill", "AI analyst chat", "Ask about any stock, sector or your portfolio in English or Arabic."),
    ]

    @State private var glow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Theme.gold.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 110))
                            .frame(width: 220, height: 220)
                            .scaleEffect(glow ? 1.08 : 0.92)
                        Image(systemName: "sparkles")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(Theme.goldGradient)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    .frame(height: 170)
                    VStack(spacing: 10) {
                        Text("AI INSIGHTS").font(.overline).tracking(2).foregroundStyle(Theme.gold)
                        Text("Your analyst for the Egyptian Exchange")
                            .font(.serif(28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Coming in the next build")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.onGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.goldGradient))
                    }
                    VStack(spacing: 0) {
                        ForEach(features, id: \.1) { icon, title, detail in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.gold)
                                    .frame(width: 40, height: 40)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.goldSoft))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary)
                                    Text(detail).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    .cardStyle()
                    Text("Ratings are educational and are not investment advice.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Wordmark() } }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { glow = true }
            }
        }
    }
}
