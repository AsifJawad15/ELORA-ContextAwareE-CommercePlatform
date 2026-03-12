import Foundation
import FirebaseFirestore

final class FirebaseUserRepository: UserRepository {

    private let db = Firestore.firestore()
    private let collection = "users"

    func fetchProfile(userId: String) async throws -> UserProfile {
        let doc = try await db.collection(collection).document(userId).getDocument()
        guard let profile = try? doc.data(as: UserProfile.self) else {
            throw RepositoryError.notFound
        }
        return profile
    }

    func createProfile(profile: UserProfile) async throws {
        guard let uid = profile.id else { return }
        var data: [String: Any] = [
            "email": profile.email
        ]
        if let name = profile.displayName { data["displayName"] = name }
        if let currency = profile.preferredCurrency { data["preferredCurrency"] = currency }
        if let created = profile.createdAt { data["createdAt"] = Timestamp(date: created) }
        if let admin = profile.isAdmin { data["isAdmin"] = admin }
        try await db.collection(collection).document(uid).setData(data, merge: true)
    }

    func updateProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection(collection).document(userId).updateData(data)
    }
}
