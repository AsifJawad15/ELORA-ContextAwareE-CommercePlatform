import Foundation

struct CurrencyResponse: Codable {
    let result: String
    let base_code: String
    let rates: [String: Double]
}

struct CurrencyRate {
    let code: String
    let rate: Double
    let symbol: String

    static let supportedCurrencies: [String: String] = [
        "USD": "$",
        "EUR": "€",
        "GBP": "£",
        "BDT": "৳",
        "INR": "₹",
        "JPY": "¥",
        "AUD": "A$",
        "CAD": "C$"
    ]

    static func symbol(for code: String) -> String {
        supportedCurrencies[code] ?? code
    }
}
