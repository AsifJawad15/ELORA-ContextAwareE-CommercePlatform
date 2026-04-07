import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var profile: UserProfile?
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userRepo: UserRepository
    private let orderRepo: OrderRepository

    init(userRepo: UserRepository = FirebaseUserRepository(),
         orderRepo: OrderRepository = FirebaseOrderRepository()) {
        self.userRepo = userRepo
        self.orderRepo = orderRepo
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
}
