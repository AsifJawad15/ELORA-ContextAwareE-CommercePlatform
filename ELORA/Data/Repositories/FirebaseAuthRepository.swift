import Foundation
import FirebaseAuth

final class FirebaseAuthRepository: AuthRepository {

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func signInAsGuest() async throws -> String {
        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        try await user.delete()
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User is not authenticated."
        case .invalidCredentials: return "Invalid email or password."
        }
    }
}
