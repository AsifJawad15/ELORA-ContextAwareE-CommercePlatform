import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var profile: UserProfile?
    @Published var orders: [Order] = []
    @Published var unreadNotificationsCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userRepo: UserRepository
    private let orderRepo: OrderRepository
    private let notificationRepo: NotificationRepository

    init(userRepo: UserRepository = FirebaseUserRepository(),
         orderRepo: OrderRepository = FirebaseOrderRepository(),
         notificationRepo: NotificationRepository = FirebaseNotificationRepository()) {
        self.userRepo = userRepo
        self.orderRepo = orderRepo
        self.notificationRepo = notificationRepo
    }

    func loadProfile(userId: String) async {
        isLoading = true
        do {
            profile = try await userRepo.fetchProfile(userId: userId)
        } catch {
            // Profile may not exist for guest users
            profile = nil
        }
        isLoading = false
    }

    func loadOrders(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            orders = try await orderRepo.fetchOrders(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateDisplayName(_ name: String, userId: String) async {
        do {
            try await userRepo.updateProfile(userId: userId, data: ["displayName": name])
            profile?.displayName = name
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCurrency(_ currency: String, userId: String) async {
        do {
            try await userRepo.updateProfile(userId: userId, data: ["preferredCurrency": currency])
            profile?.preferredCurrency = currency
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNotificationCount(userId: String) async {
        do {
            let notifications = try await notificationRepo.fetchNotifications(userId: userId)
            unreadNotificationsCount = notifications.filter { !$0.isRead }.count
        } catch {
            unreadNotificationsCount = 0
        }
    }

    func saveAddress(_ address: Address, userId: String) async {
        let trimmed = normalized(address)
        guard !trimmed.isBlank else { return }

        var addresses = profile?.savedAddresses ?? []
        addresses.removeAll { normalized($0) == trimmed }
        addresses.insert(trimmed, at: 0)
        addresses = Array(addresses.prefix(5))

        do {
            try await userRepo.updateProfile(
                userId: userId,
                data: ["savedAddresses": addresses.map(\.firestoreData)]
            )
            profile?.savedAddresses = addresses
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func upsertAddress(_ address: Address, at index: Int?, userId: String) async {
        let trimmed = normalized(address)
        guard !trimmed.isBlank else { return }

        var addresses = profile?.savedAddresses ?? []

        if let index, addresses.indices.contains(index) {
            addresses[index] = trimmed
        } else {
            addresses.removeAll { normalized($0) == trimmed }
            addresses.insert(trimmed, at: 0)
        }

        addresses = Array(addresses.prefix(5))

        do {
            try await userRepo.updateProfile(
                userId: userId,
                data: ["savedAddresses": addresses.map(\.firestoreData)]
            )
            profile?.savedAddresses = addresses
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAddress(at index: Int, userId: String) async {
        var addresses = profile?.savedAddresses ?? []
        guard addresses.indices.contains(index) else { return }
        addresses.remove(at: index)

        do {
            try await userRepo.updateProfile(
                userId: userId,
                data: ["savedAddresses": addresses.map(\.firestoreData)]
            )
            profile?.savedAddresses = addresses
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeDefaultAddress(at index: Int, userId: String) async {
        var addresses = profile?.savedAddresses ?? []
        guard addresses.indices.contains(index), index != 0 else { return }
        let selected = addresses.remove(at: index)
        addresses.insert(selected, at: 0)

        do {
            try await userRepo.updateProfile(
                userId: userId,
                data: ["savedAddresses": addresses.map(\.firestoreData)]
            )
            profile?.savedAddresses = addresses
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func normalized(_ address: Address) -> Address {
        Address(
            fullName: address.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: address.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            street: address.street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: address.city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: address.state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: address.zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: address.country.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
