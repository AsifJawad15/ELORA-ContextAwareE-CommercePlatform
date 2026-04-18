import Foundation
import UserNotifications
import FirebaseMessaging
import UIKit

/// Manages push notification registration (FCM) and local notification scheduling.
/// Requires: Push Notifications capability + APNs key in Firebase Console.
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    static let shared = NotificationService()

    @Published var isPermissionGranted = false
    @Published var fcmToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Setup (call from AppDelegate)

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    // MARK: - Request Permission

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                isPermissionGranted = granted
            }
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
        }
    }

    // MARK: - Topic Subscription

    func subscribeToTopics() {
        Messaging.messaging().subscribe(toTopic: "deals") { error in
            if let error { print("Deals topic error: \(error)") }
        }
        Messaging.messaging().subscribe(toTopic: "coupons") { error in
            if let error { print("Coupons topic error: \(error)") }
        }
        Messaging.messaging().subscribe(toTopic: "promotions") { error in
            if let error { print("Promotions topic error: \(error)") }
        }
    }

    // MARK: - Local Notifications (for coupon/deal alerts)

    func scheduleLocalNotification(
        title: String,
        body: String,
        delay: TimeInterval = 1
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 1),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule a deal expiry reminder
    func scheduleDealReminder(title: String, endsAt: Date) {
        let reminderDate = endsAt.addingTimeInterval(-3600) // 1 hour before expiry
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Deal Ending Soon!"
        content.body = "\(title) expires in 1 hour. Don't miss out!"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "deal-\(title.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Display notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Can route to specific screen based on notification data
        print("Notification tapped: \(userInfo)")
        completionHandler()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
        }
    }
}
