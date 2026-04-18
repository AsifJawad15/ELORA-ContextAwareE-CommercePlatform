import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {

    @Published var notifications: [BuyerNotification] = []
    @Published var claimedCouponCodes: Set<String> = []
    @Published var activeCoupons: [String: Coupon] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let notificationRepo: NotificationRepository
    private let userRepo: UserRepository
    private let couponRepo: CouponRepository

    init(
        notificationRepo: NotificationRepository = FirebaseNotificationRepository(),
        userRepo: UserRepository = FirebaseUserRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository()
    ) {
        self.notificationRepo = notificationRepo
        self.userRepo = userRepo
        self.couponRepo = couponRepo
    }

    func load(userId: String) async {
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            async let notificationRequest = notificationRepo.fetchNotifications(userId: userId)
            async let profileRequest = userRepo.fetchProfile(userId: userId)
            async let couponsRequest = couponRepo.fetchActiveCoupons()

            let fetchedNotifications = try await notificationRequest
            let profile = try await profileRequest
            let coupons = try await couponsRequest

            notifications = fetchedNotifications
            claimedCouponCodes = Set((profile.claimedCouponCodes ?? []).map { $0.uppercased() })
            activeCoupons = coupons.reduce(into: [String: Coupon]()) { result, coupon in
                let key = coupon.code.uppercased()
                if result[key] == nil {
                    result[key] = coupon
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func markAllAsRead(userId: String) async {
        do {
            try await notificationRepo.markAllAsRead(userId: userId)
            notifications = notifications.map { notification in
                var copy = notification
                copy.isRead = true
                return copy
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(notification: BuyerNotification) async {
        guard let id = notification.id, !notification.isRead else { return }

        do {
            try await notificationRepo.markAsRead(notificationId: id)
            notifications = notifications.map { current in
                guard current.id == notification.id else { return current }
                var copy = current
                copy.isRead = true
                return copy
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func claimCoupon(code: String, userId: String, notification: BuyerNotification? = nil) async {
        let normalized = code.uppercased()
        if claimedCouponCodes.contains(normalized) {
            if let notification {
                await markAsRead(notification: notification)
            }
            return
        }

        var updatedCodes = claimedCouponCodes
        updatedCodes.insert(normalized)

        do {
            try await userRepo.updateProfile(
                userId: userId,
                data: ["claimedCouponCodes": Array(updatedCodes).sorted()]
            )
            claimedCouponCodes = updatedCodes
            if let notification {
                await markAsRead(notification: notification)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func coupon(for notification: BuyerNotification) -> Coupon? {
        guard let code = notification.couponCode?.uppercased() else { return nil }
        return activeCoupons[code]
    }
}
