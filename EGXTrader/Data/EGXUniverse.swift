import Foundation

/// The tradable universe: a representative set of the most liquid EGX-listed
/// companies. Reference prices are indicative and only seed the simulated feed.
enum EGXUniverse {
    static let stocks: [Stock] = [
        // Banks
        Stock(symbol: "COMI", name: "Commercial International Bank", nameAr: "البنك التجاري الدولي", sector: .banks,
              sharesOutstandingM: 3_070, referencePrice: 82.40, dailyVolatility: 0.017, peRatio: 6.1, dividendYield: 3.1, isEGX30: true),
        Stock(symbol: "CIEB", name: "Crédit Agricole Egypt", nameAr: "كريدي أجريكول مصر", sector: .banks,
              sharesOutstandingM: 1_250, referencePrice: 23.15, dailyVolatility: 0.018, peRatio: 4.8, dividendYield: 8.2, isEGX30: true),
        Stock(symbol: "ADIB", name: "Abu Dhabi Islamic Bank Egypt", nameAr: "مصرف أبوظبي الإسلامي مصر", sector: .banks,
              sharesOutstandingM: 1_000, referencePrice: 38.60, dailyVolatility: 0.022, peRatio: 4.2, dividendYield: 2.4, isEGX30: true),
        Stock(symbol: "HDBK", name: "Housing & Development Bank", nameAr: "بنك التعمير والإسكان", sector: .banks,
              sharesOutstandingM: 530, referencePrice: 91.30, dailyVolatility: 0.020, peRatio: 3.6, dividendYield: 6.5, isEGX30: true),
        // Financial services
        Stock(symbol: "HRHO", name: "EFG Holding", nameAr: "إي إف جي القابضة", sector: .nonBankFinancial,
              sharesOutstandingM: 1_460, referencePrice: 26.85, dailyVolatility: 0.021, peRatio: 8.9, dividendYield: 1.9, isEGX30: true),
        Stock(symbol: "FWRY", name: "Fawry for Banking & Payment", nameAr: "فوري لتكنولوجيا البنوك", sector: .nonBankFinancial,
              sharesOutstandingM: 3_560, referencePrice: 12.74, dailyVolatility: 0.026, peRatio: 21.4, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "EFIH", name: "e-finance for Digital Investments", nameAr: "إي فاينانس للاستثمارات المالية", sector: .nonBankFinancial,
              sharesOutstandingM: 1_780, referencePrice: 21.90, dailyVolatility: 0.023, peRatio: 17.8, dividendYield: 1.2, isEGX30: true),
        Stock(symbol: "BTFH", name: "Beltone Holding", nameAr: "بلتون القابضة", sector: .nonBankFinancial,
              sharesOutstandingM: 6_000, referencePrice: 3.12, dailyVolatility: 0.032, peRatio: 25.0, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "CCAP", name: "Qalaa Holdings", nameAr: "القلعة للاستشارات المالية", sector: .nonBankFinancial,
              sharesOutstandingM: 1_820, referencePrice: 2.86, dailyVolatility: 0.034, peRatio: 11.2, dividendYield: 0.0, isEGX30: true),
        // Real estate
        Stock(symbol: "TMGH", name: "Talaat Moustafa Group", nameAr: "مجموعة طلعت مصطفى القابضة", sector: .realEstate,
              sharesOutstandingM: 2_060, referencePrice: 61.25, dailyVolatility: 0.022, peRatio: 12.3, dividendYield: 1.6, isEGX30: true),
        Stock(symbol: "PHDC", name: "Palm Hills Developments", nameAr: "بالم هيلز للتعمير", sector: .realEstate,
              sharesOutstandingM: 3_100, referencePrice: 7.38, dailyVolatility: 0.027, peRatio: 6.9, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "EMFD", name: "Emaar Misr for Development", nameAr: "إعمار مصر للتنمية", sector: .realEstate,
              sharesOutstandingM: 4_530, referencePrice: 7.05, dailyVolatility: 0.025, peRatio: 5.4, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "MASR", name: "Madinet Masr for Housing", nameAr: "مدينة مصر للإسكان والتعمير", sector: .realEstate,
              sharesOutstandingM: 2_140, referencePrice: 4.62, dailyVolatility: 0.029, peRatio: 5.9, dividendYield: 2.1, isEGX30: true),
        Stock(symbol: "ORHD", name: "Orascom Development Egypt", nameAr: "أوراسكوم للتنمية مصر", sector: .realEstate,
              sharesOutstandingM: 1_120, referencePrice: 24.70, dailyVolatility: 0.028, peRatio: 7.7, dividendYield: 0.0, isEGX30: true),
        // Basic resources
        Stock(symbol: "ABUK", name: "Abu Qir Fertilizers", nameAr: "أبوقير للأسمدة والصناعات الكيماوية", sector: .basicResources,
              sharesOutstandingM: 1_260, referencePrice: 51.80, dailyVolatility: 0.019, peRatio: 7.2, dividendYield: 9.4, isEGX30: true),
        Stock(symbol: "MFPC", name: "Misr Fertilizers Production (MOPCO)", nameAr: "مصر لإنتاج الأسمدة - موبكو", sector: .basicResources,
              sharesOutstandingM: 1_140, referencePrice: 39.40, dailyVolatility: 0.021, peRatio: 6.4, dividendYield: 7.8, isEGX30: true),
        Stock(symbol: "ESRS", name: "Ezz Steel", nameAr: "حديد عز", sector: .basicResources,
              sharesOutstandingM: 543, referencePrice: 94.10, dailyVolatility: 0.026, peRatio: 5.1, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "EGAL", name: "Egypt Aluminum", nameAr: "مصر للألومنيوم", sector: .basicResources,
              sharesOutstandingM: 412, referencePrice: 198.50, dailyVolatility: 0.024, peRatio: 6.8, dividendYield: 5.5, isEGX30: false),
        Stock(symbol: "SKPC", name: "Sidi Kerir Petrochemicals", nameAr: "سيدي كرير للبتروكيماويات", sector: .energy,
              sharesOutstandingM: 756, referencePrice: 18.35, dailyVolatility: 0.021, peRatio: 8.1, dividendYield: 7.1, isEGX30: true),
        Stock(symbol: "AMOC", name: "Alexandria Mineral Oils", nameAr: "الإسكندرية للزيوت المعدنية", sector: .energy,
              sharesOutstandingM: 1_290, referencePrice: 7.92, dailyVolatility: 0.024, peRatio: 7.4, dividendYield: 8.6, isEGX30: true),
        // Industrial & construction
        Stock(symbol: "SWDY", name: "Elsewedy Electric", nameAr: "السويدي إليكتريك", sector: .industrial,
              sharesOutstandingM: 2_180, referencePrice: 76.20, dailyVolatility: 0.020, peRatio: 9.6, dividendYield: 1.3, isEGX30: true),
        Stock(symbol: "ORAS", name: "Orascom Construction", nameAr: "أوراسكوم كونستراكشون", sector: .construction,
              sharesOutstandingM: 110, referencePrice: 312.00, dailyVolatility: 0.018, peRatio: 6.7, dividendYield: 4.0, isEGX30: true),
        Stock(symbol: "GBCO", name: "GB Corp", nameAr: "جي بي كورب", sector: .industrial,
              sharesOutstandingM: 1_090, referencePrice: 17.25, dailyVolatility: 0.027, peRatio: 6.2, dividendYield: 0.0, isEGX30: true),
        // Telecom & tech
        Stock(symbol: "ETEL", name: "Telecom Egypt", nameAr: "المصرية للاتصالات", sector: .telecomTech,
              sharesOutstandingM: 1_707, referencePrice: 37.95, dailyVolatility: 0.017, peRatio: 5.8, dividendYield: 4.6, isEGX30: true),
        // Consumer, food & beverage
        Stock(symbol: "EAST", name: "Eastern Company", nameAr: "الشرقية للدخان - إيسترن كومباني", sector: .consumer,
              sharesOutstandingM: 3_000, referencePrice: 30.40, dailyVolatility: 0.015, peRatio: 8.4, dividendYield: 7.9, isEGX30: true),
        Stock(symbol: "ORWE", name: "Oriental Weavers", nameAr: "السجاد الشرقي - النساجون الشرقيون", sector: .consumer,
              sharesOutstandingM: 665, referencePrice: 20.60, dailyVolatility: 0.019, peRatio: 7.1, dividendYield: 6.3, isEGX30: true),
        Stock(symbol: "JUFO", name: "Juhayna Food Industries", nameAr: "جهينة للصناعات الغذائية", sector: .foodBeverage,
              sharesOutstandingM: 941, referencePrice: 20.15, dailyVolatility: 0.020, peRatio: 10.8, dividendYield: 2.7, isEGX30: true),
        Stock(symbol: "EFID", name: "Edita Food Industries", nameAr: "إيديتا للصناعات الغذائية", sector: .foodBeverage,
              sharesOutstandingM: 699, referencePrice: 25.30, dailyVolatility: 0.019, peRatio: 13.5, dividendYield: 3.2, isEGX30: false),
        // Healthcare
        Stock(symbol: "CLHO", name: "Cleopatra Hospitals Group", nameAr: "مجموعة مستشفيات كليوباترا", sector: .healthcare,
              sharesOutstandingM: 1_600, referencePrice: 9.14, dailyVolatility: 0.021, peRatio: 16.2, dividendYield: 0.0, isEGX30: true),
        Stock(symbol: "ISPH", name: "Ibnsina Pharma", nameAr: "ابن سينا فارما", sector: .healthcare,
              sharesOutstandingM: 1_050, referencePrice: 5.08, dailyVolatility: 0.025, peRatio: 11.9, dividendYield: 1.5, isEGX30: false),
    ]

    static let bySymbol: [String: Stock] = Dictionary(uniqueKeysWithValues: stocks.map { ($0.symbol, $0) })

    struct IndexDefinition {
        let code: String
        let name: String
        let referenceValue: Double
        /// Market-cap weighted when true, equal weighted otherwise.
        let capWeighted: Bool
        let includes: (Stock) -> Bool
    }

    static let indices: [IndexDefinition] = [
        IndexDefinition(code: "EGX30", name: "EGX 30", referenceValue: 41_862.35, capWeighted: true,
                        includes: { $0.isEGX30 }),
        IndexDefinition(code: "EGX70", name: "EGX 70 EWI", referenceValue: 10_486.12, capWeighted: false,
                        includes: { !$0.isEGX30 || $0.referencePrice < 10 }),
        IndexDefinition(code: "EGX100", name: "EGX 100 EWI", referenceValue: 14_210.48, capWeighted: false,
                        includes: { _ in true }),
        IndexDefinition(code: "EGX33", name: "EGX 33 Shariah", referenceValue: 3_978.60, capWeighted: true,
                        includes: { stock in
                            // Excludes conventional banks and interest-driven financials.
                            switch stock.sector {
                            case .banks: return stock.symbol == "ADIB"
                            case .nonBankFinancial: return false
                            case .consumer: return stock.symbol != "EAST"
                            default: return true
                            }
                        }),
    ]

    /// Default watchlist for new users.
    static let defaultWatchlist = ["COMI", "TMGH", "ETEL", "SWDY", "FWRY", "ABUK"]
}
