import Foundation
import FirebaseFirestore

final class FirebaseNotificationRepository: NotificationRepository {

    private let db = Firestore.firestore()
    private let collection = "notifications"

    func fetchNotifications(userId: String) async throws -> [BuyerNotification] {
        // Avoid the composite index requirement by fetching the user's notifications
        // first, then sorting locally by created date.
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: BuyerNotification.self) }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func createNotification(_ notification: BuyerNotification) async throws {
        _ = try db.collection(collection).addDocument(from: notification)
    }

    func createNotifications(_ notifications: [BuyerNotification]) async throws {
        guard !notifications.isEmpty else { return }
        let batch = db.batch()

        for notification in notifications {
            let doc = db.collection(collection).document()
            try batch.setData(from: notification, forDocument: doc)
        }

        try await batch.commit()
    }

    func markAsRead(notificationId: String) async throws {
        try await db.collection(collection).document(notificationId).updateData([
            "isRead": true
        ])
    }

    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        try await batch.commit()
    }
}
