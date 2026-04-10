import Foundation

/// Mock payment service backed by bundled pseudo gateway data.
final class MockPaymentService {

    static let shared = MockPaymentService()
    private let gateway = MockPaymentGateway.shared

    private init() {}

    struct PaymentResult {
        let success: Bool
        let transactionId: String
        let message: String
    }

    func availablePaymentMethods() -> [MockPaymentGateway.PaymentMethodDefinition] {
        gateway.paymentMethods()
    }

    func confirmPayment(
        methodId: String,
        payerReference: String,
        amount: Double,
        currency: String,
        orderId: String
    ) async throws -> PaymentResult {
        let response = try await gateway.confirmPayment(
            methodId: methodId,
            payerReference: payerReference,
            amount: amount,
            currency: currency,
            orderId: orderId
        )

        return PaymentResult(
            success: response.success,
            transactionId: response.transactionId,
            message: response.message
        )
    }

    /// Simulates a card payment against the bundled pseudo gateway.
    func processPayment(
        amount: Double,
        currency: String,
        cardLastFour: String,
        orderId: String
    ) async throws -> PaymentResult {
        let response = try await gateway.authorizePayment(
            amount: amount,
            currency: currency,
            cardLastFour: cardLastFour,
            orderId: orderId
        )

        return PaymentResult(
            success: response.success,
            transactionId: response.transactionId,
            message: response.message
        )
    }

    /// Simulates shipping rate calculation from bundled pseudo data.
    func calculateShipping(
        country: String,
        subtotal: Double
    ) async throws -> Double {
        gateway.shippingQuote(country: country, subtotal: subtotal)
    }
}
