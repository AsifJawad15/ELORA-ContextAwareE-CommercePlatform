//
//  ELORAApp.swift
//  ELORA
//
//  Created by macos on 28/2/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct ELORAApp: App {

    @StateObject private var authVM = AuthViewModel()
    @StateObject private var currencyService = CurrencyService.shared
    @State private var isAdminMode = false
    @State private var isAdminLoggedIn = false

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
                } else if authVM.isAuthenticated {
                    MainTabView(
                        authVM: authVM,
                        currencyService: currencyService
                    )
                } else {
                    LoginView(viewModel: authVM, onAdminLogin: { isAdminMode = true })
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
