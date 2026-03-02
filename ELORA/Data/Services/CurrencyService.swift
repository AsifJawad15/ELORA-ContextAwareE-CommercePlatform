import Foundation

/// Fetches live exchange rates from open.er-api.com (free, no key needed).
final class CurrencyService: ObservableObject {

    static let shared = CurrencyService()

    @Published var rates: [String: Double] = [:]
    @Published var selectedCurrency: String = "USD"
    @Published var isLoading = false

    private let baseURL = "https://open.er-api.com/v6/latest/USD"
    private var cachedAt: Date?
    private let cacheInterval: TimeInterval = 3600 // 1 hour

    private init() {}

    /// Fetches rates if cache is stale.
    func fetchRatesIfNeeded() async {
        if let cached = cachedAt, Date().timeIntervalSince(cached) < cacheInterval,
           !rates.isEmpty {
            return
        }
        await fetchRates()
    }

    func fetchRates() async {
        await MainActor.run { isLoading = true }
        do {
            let response: CurrencyResponse = try await APIClient.get(baseURL)
            await MainActor.run {
                self.rates = response.rates
                self.cachedAt = Date()
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
            print("CurrencyService error: \(error.localizedDescription)")
        }
    }

    /// Convert USD price to selected currency.
    func convert(_ usdPrice: Double) -> Double {
        guard selectedCurrency != "USD",
              let rate = rates[selectedCurrency] else {
            return usdPrice
        }
        return usdPrice * rate
    }

    /// Formatted price string in selected currency.
    func formatted(_ usdPrice: Double) -> String {
        let converted = convert(usdPrice)
        let symbol = CurrencyRate.symbol(for: selectedCurrency)
        return "\(symbol)\(String(format: "%.2f", converted))"
    }
}
