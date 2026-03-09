import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String?
    var photoUrl: String?
    var phone: String?
    var savedAddresses: [Address]?
    var preferredCurrency: String?
    var createdAt: Date?

    static let guest = UserProfile(
        email: "guest@elora.app",
        displayName: "Guest",
        preferredCurrency: "USD"
    )
}
