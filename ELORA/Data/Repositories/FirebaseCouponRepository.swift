import Foundation
import FirebaseFirestore


final class FirebaseCouponRepository: CouponRepository {

    private let db = Firestore.firestore()
    private let collection = "coupons"

    func validateCoupon(code: String) async throws -> Coupon {
        let snapshot = try await db.collection(collection)
            .whereField("code", isEqualTo: code.uppercased())
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        let coupons = try snapshot.documents.compactMap {
            try $0.data(as: Coupon.self)
        }

        guard let coupon = deduplicatedCoupons(coupons).first else {
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

        let coupons = try snapshot.documents.compactMap {
            try $0.data(as: Coupon.self)
        }

        return deduplicatedCoupons(coupons)
    }

    // MARK: - Admin CRUD

    func addCoupon(_ data: [String: Any]) async throws -> String {
        try await ensureUniqueCouponCode(for: data["code"] as? String, ignoring: nil)
        let docRef = try await db.collection(collection).addDocument(data: data)
        return docRef.documentID
    }

    func updateCoupon(id: String, data: [String: Any]) async throws {
        try await ensureUniqueCouponCode(for: data["code"] as? String, ignoring: id)
        try await db.collection(collection).document(id).updateData(data)
    }

    func deleteCoupon(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    private func ensureUniqueCouponCode(for rawCode: String?, ignoring documentId: String?) async throws {
        guard let rawCode, !rawCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let normalizedCode = rawCode.uppercased()
        let snapshot = try await db.collection(collection)
            .whereField("code", isEqualTo: normalizedCode)
            .getDocuments()

        let hasDuplicate = snapshot.documents.contains { document in
            document.documentID != documentId
        }

        if hasDuplicate {
            throw CouponError.duplicateCode(normalizedCode)
        }
    }

    private func deduplicatedCoupons(_ coupons: [Coupon]) -> [Coupon] {
        let now = Date()

        return coupons
            .filter { coupon in
                guard let expiresAt = coupon.expiresAt else { return true }
                return expiresAt >= now
            }
            .reduce(into: [String: Coupon]()) { result, coupon in
                let key = coupon.code.uppercased()
                if let existing = result[key] {
                    result[key] = preferredCoupon(existing, coupon)
                } else {
                    result[key] = coupon
                }
            }
            .values
            .sorted { lhs, rhs in
                let lhsExpiry = lhs.expiresAt ?? .distantFuture
                let rhsExpiry = rhs.expiresAt ?? .distantFuture
                if lhsExpiry == rhsExpiry {
                    return lhs.code < rhs.code
                }
                return lhsExpiry < rhsExpiry
            }
    }

    private func preferredCoupon(_ lhs: Coupon, _ rhs: Coupon) -> Coupon {
        let lhsExpiry = lhs.expiresAt ?? .distantFuture
        let rhsExpiry = rhs.expiresAt ?? .distantFuture

        if lhsExpiry != rhsExpiry {
            return lhsExpiry > rhsExpiry ? lhs : rhs
        }

        if lhs.discountValue != rhs.discountValue {
            return lhs.discountValue > rhs.discountValue ? lhs : rhs
        }

        return lhs.id ?? "" <= rhs.id ?? "" ? lhs : rhs
    }
}

enum CouponError: LocalizedError {
    case invalidCode
    case expired
    case minimumNotMet
    case duplicateCode(String)

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid coupon code."
        case .expired: return "This coupon has expired."
        case .minimumNotMet: return "Minimum order amount not reached."
        case .duplicateCode(let code): return "Coupon code \(code) already exists."
        }
    }
}
