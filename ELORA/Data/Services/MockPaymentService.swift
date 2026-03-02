import Foundation

/// Mock payment service using httpbin.org/post to simulate real API calls.
final class MockPaymentService {

    static let shared = MockPaymentService()
    private init() {}

    struct PaymentResult {
        let success: Bool
        let transactionId: String
        let message: String
    }

    /// Simulates a payment POST to httpbin.org (echoes back the data).
    func processPayment(
        amount: Double,
        currency: String,
        cardLastFour: String,
        orderId: String
    ) async throws -> PaymentResult {

        let body: [String: Any] = [
            "amount": amount,
            "currency": currency,
            "card_last_four": cardLastFour,
            "order_id": orderId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        let _ = try await APIClient.post("https://httpbin.org/post", body: body)

        // Simulate success (httpbin echoes data back, status 200 = success)
        let txId = "TXN-\(UUID().uuidString.prefix(8).uppercased())"
        return PaymentResult(
            success: true,
            transactionId: txId,
            message: "Payment of \(CurrencyRate.symbol(for: currency))\(String(format: "%.2f", amount)) processed successfully."
        )
    }

    /// Simulates shipping rate calculation.
    func calculateShipping(
        country: String,
        subtotal: Double
    ) async throws -> Double {
        // Free shipping over $100
        if subtotal >= 100 {
            return 0
        }

        let body: [String: Any] = [
            "country": country,
            "subtotal": subtotal,
            "method": "standard"
        ]

        let _ = try await APIClient.post("https://httpbin.org/post", body: body)

        // Mock shipping rates
        switch country.lowercased() {
        case "us", "usa", "united states":
            return 5.99
        case "bd", "bangladesh":
            return 3.50
        default:
            return 9.99
        }
    }
}
