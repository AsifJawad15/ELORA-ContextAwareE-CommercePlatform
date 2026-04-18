//
//  ELORAApp.swift
//  ELORA
//
//  Created by macos on 28/2/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationService.shared.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct ELORAApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var currencyService = CurrencyService.shared
    @State private var isAdminMode = false
    @State private var isAdminLoggedIn = false
    @State private var isResolvingSession = true

    init() {
        FirebaseApp.configure()

        // Appearance customization
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Seed sample data on first launch
        FirestoreSeeder.shared.seedIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAdminMode {
                    if isAdminLoggedIn {
                        AdminDashboardView(
                            onLogout: {
                                try? Auth.auth().signOut()
                                isAdminLoggedIn = false
                                isAdminMode = false
                            }
                        )
                    } else {
                        AdminLoginView(
                            isAdminLoggedIn: $isAdminLoggedIn,
                            onBackToUser: { isAdminMode = false }
                        )
                    }
                } else if !isResolvingSession && authVM.isAuthenticated {
                    MainTabView(
                        authVM: authVM,
                        currencyService: currencyService
                    )
                } else {
                    LoginView(viewModel: authVM, onAdminLogin: { isAdminMode = true })
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await NotificationService.shared.requestPermission()
                NotificationService.shared.subscribeToTopics()
            }
            .task {
                await resolveLaunchSession()
            }
        }
    }

    @MainActor
    private func resolveLaunchSession() async {
        guard let user = Auth.auth().currentUser else {
            isAdminMode = false
            isAdminLoggedIn = false
            isResolvingSession = false
            return
        }

        if !user.isAnonymous {
            do {
                try await user.reload()
            } catch {
                try? Auth.auth().signOut()
                isAdminMode = false
                isAdminLoggedIn = false
                isResolvingSession = false
                return
            }

            guard Auth.auth().currentUser?.isEmailVerified == true else {
                try? Auth.auth().signOut()
                isAdminMode = false
                isAdminLoggedIn = false
                isResolvingSession = false
                return
            }
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .getDocument()

            if let profile = try? snapshot.data(as: UserProfile.self), profile.isAdmin == true {
                isAdminMode = true
                isAdminLoggedIn = true
            } else {
                isAdminMode = false
                isAdminLoggedIn = false
            }
        } catch {
            isAdminMode = false
            isAdminLoggedIn = false
        }

        isResolvingSession = false
    }
}
