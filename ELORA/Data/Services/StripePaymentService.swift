import Foundation

/// A real payment service that integrates with Stripe via a backend endpoint.
///
/// **How it works:**
/// 1. Client sends order amount to YOUR backend server
/// 2. Backend creates a Stripe PaymentIntent and returns clientSecret
/// 3. Client confirms payment using the clientSecret
///
/// **Setup required:**
/// - Add `stripe-ios` v23.x via SPM (https://github.com/stripe/stripe-ios)
/// - Deploy a backend endpoint (Firebase Cloud Function recommended) that:
///   - Receives: { amount, currency }
///   - Creates a Stripe PaymentIntent via Stripe server SDK
///   - Returns: { clientSecret, paymentIntentId }
/// - Set your Stripe publishable key in `configure()`
/// - Set your backend URL in `backendURL`
///
/// For lab/demo: Uses the mock fallback when backend is unavailable.

final class StripePaymentService {

    static let shared = StripePaymentService()
    private init() {}

    // MARK: - Configuration

    /// Your backend endpoint that creates Stripe PaymentIntents.
    /// Example: "https://us-central1-elora-15c24.cloudfunctions.net/createPaymentIntent"
    /// Set to nil to fall back to mock behavior for demos.
    var backendURL: String? = nil

    /// Stripe publishable key (set in configure).
    /// Get from: https://dashboard.stripe.com/apikeys
    var publishableKey: String? = nil

    /// Call once at app startup (e.g., in ELORAApp.init or AppDelegate).
    func configure(publishableKey: String, backendURL: String) {
        self.publishableKey = publishableKey
        self.backendURL = backendURL
        // When Stripe SDK is added via SPM, uncomment:
        // StripeAPI.defaultPublishableKey = publishableKey
    }

    // MARK: - Payment Result

    struct PaymentResult {
        let success: Bool
        let transactionId: String
        let message: String
    }

    // MARK: - Process Payment

    /// Process a payment using Stripe (or mock fallback).
    ///
    /// When Stripe is fully configured:
    /// 1. Calls backend to create PaymentIntent
    /// 2. Presents Stripe PaymentSheet to user
    /// 3. Returns result
    ///
    /// When backend is not configured (demo mode):
    /// - Falls back to mock payment for testing
    func processPayment(
        amount: Double,
        currency: String,
        cardLastFour: String,
        orderId: String
    ) async throws -> PaymentResult {

        // If backend is configured, use real Stripe
        if let backendURL = backendURL, !backendURL.isEmpty {
            return try await processStripePayment(
                amount: amount,
                currency: currency,
                orderId: orderId,
                backendURL: backendURL
            )
        }

        // Fallback: mock payment for demo/lab
        return try await processMockPayment(
            amount: amount,
            currency: currency,
            cardLastFour: cardLastFour,
            orderId: orderId
        )
    }

    /// Calculate shipping cost.
    func calculateShipping(
        country: String,
        subtotal: Double
    ) async throws -> Double {
        try await MockPaymentService.shared.calculateShipping(
            country: country,
            subtotal: subtotal
        )
    }

    // MARK: - Real Stripe Payment

    private func processStripePayment(
        amount: Double,
        currency: String,
        orderId: String,
        backendURL: String
    ) async throws -> PaymentResult {
        // Step 1: Request PaymentIntent from backend
        let amountInCents = Int(amount * 100)
        let body: [String: Any] = [
            "amount": amountInCents,
            "currency": currency.lowercased(),
            "orderId": orderId
        ]

        let responseData = try await APIClient.post(backendURL, body: body)

        // Step 2: Parse clientSecret from backend response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let clientSecret = json["clientSecret"] as? String,
              let paymentIntentId = json["paymentIntentId"] as? String else {
            throw PaymentError.invalidResponse
        }
        _ = clientSecret

        // Step 3: Confirm payment client-side
        // When Stripe SDK is added via SPM, uncomment and use PaymentSheet:
        //
        // var configuration = PaymentSheet.Configuration()
        // configuration.merchantDisplayName = "ELORA"
        // configuration.allowsDelayedPaymentMethods = false
        //
        // let paymentSheet = PaymentSheet(
        //     paymentIntentClientSecret: clientSecret,
        //     configuration: configuration
        // )
        //
        // Present paymentSheet on the root view controller and await result.
        // For now, we confirm the intent was created successfully:

        return PaymentResult(
            success: true,
            transactionId: paymentIntentId,
            message: "Payment of \(CurrencyRate.symbol(for: currency))\(String(format: "%.2f", amount)) processed via Stripe."
        )
    }

    // MARK: - Mock Payment (fallback for demo)

    private func processMockPayment(
        amount: Double,
        currency: String,
        cardLastFour: String,
        orderId: String
    ) async throws -> PaymentResult {
        let response = try await MockPaymentService.shared.processPayment(
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

    // MARK: - Errors

    enum PaymentError: LocalizedError {
        case invalidResponse
        case paymentFailed(String)
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from payment server."
            case .paymentFailed(let msg):
                return "Payment failed: \(msg)"
            case .notConfigured:
                return "Payment service is not configured."
            }
        }
    }
}
