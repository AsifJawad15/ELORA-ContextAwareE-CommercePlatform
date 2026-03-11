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
        try db.collection(collection).document(uid).setData(from: profile)
    }

    func updateProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection(collection).document(userId).updateData(data)
    }
}
