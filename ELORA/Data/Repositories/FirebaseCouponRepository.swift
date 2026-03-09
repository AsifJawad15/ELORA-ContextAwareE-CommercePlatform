import Foundation
import FirebaseFirestore


final class FirebaseCouponRepository: CouponRepository {

    private let db = Firestore.firestore()
    private let collection = "coupons"

    func validateCoupon(code: String) async throws -> Coupon {
        let snapshot = try await db.collection(collection)
            .whereField("code", isEqualTo: code.uppercased())
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              let coupon = try? doc.data(as: Coupon.self) else {
            throw CouponError.invalidCode
        }

        if let expires = coupon.expiresAt, expires < Date() {
            throw CouponError.expired
        }

        return coupon
    }

    func fetchActiveCoupons() async throws -> [Coupon] {
        let snapshot = try await db.collection(collection)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Coupon.self)
        }
    }
}

enum CouponError: LocalizedError {
    case invalidCode
    case expired
    case minimumNotMet

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid coupon code."
        case .expired: return "This coupon has expired."
        case .minimumNotMet: return "Minimum order amount not reached."
        }
    }
}
