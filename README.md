# ELORA

ELORA is a SwiftUI iOS e-commerce application built around a fashion and accessories storefront. The project combines Firebase-backed product and user data with a polished customer flow, an admin dashboard, notifications, location-assisted checkout, multi-currency pricing, and a sandbox payment experience for demo and lab use.

## Overview

The app supports two main experiences:

- Customer flow for browsing products, managing favorites and cart, applying coupons, and placing orders
- Admin flow for managing products, orders, coupons, and deals

The codebase is organized into clear layers:

- `App` for routing and application shell
- `Presentation` for SwiftUI views and view models
- `Data` for Firebase repositories, services, and seed data
- `Domain` for models and repository protocols

## Key Features

- Email sign up and sign in with verification
- Guest browsing mode
- Firebase Firestore catalog, coupons, deals, reviews, orders, cart, favorites, and notifications
- Admin login based on `users/{uid}.isAdmin`
- Home, shop, favorites, profile, and checkout flows
- Saved addresses with optional current-location autofill
- Multi-currency display using live exchange rates
- Buyer notifications for coupons, deals, and order updates
- Mock payment gateway for Stripe-style, wallet-style, and COD demo flows
- Firestore seeding for sample products, deals, and coupons

## Tech Stack

- SwiftUI
- Swift 5.7
- iOS deployment target: 16.1
- Firebase Auth
- Firebase Firestore
- Firebase Messaging
- Firebase Analytics
- Core Location
- MapKit
- Swift Package Manager

## Architecture

ELORA uses explicit dependency passing instead of hidden global view state.

- `ELORAApp.swift` owns app-level state like `AuthViewModel` and `CurrencyService`
- `MainTabView` in `AppRouter.swift` owns shared customer session state like `CartViewModel` and `FavoritesViewModel`
- Feature screens create their own feature view models with `@StateObject`
- Child views observe parent-owned objects with `@ObservedObject`
- Forms and reusable components communicate with `@Binding`
- Repository protocols in `Domain/Protocols/Repositories.swift` decouple view models from Firebase implementations

Notably, the project does not use `@EnvironmentObject`. Shared state is passed explicitly through the view hierarchy.

## Main Flows

### Customer Flow

1. `ELORAApp.swift` starts Firebase, notifications, appearance setup, and Firestore seeding
2. `AuthViewModel` resolves login state
3. `MainTabView` presents:
   - Home
   - Shop
   - Favorites
   - Profile
4. Users can:
   - browse products and active deals
   - add products to favorites
   - add products to cart
   - proceed through a 3-step checkout
5. Checkout:
   - collects or reuses saved address data
   - applies coupons
   - calculates shipping
   - confirms payment through the mock gateway
   - creates an order in Firestore
   - creates a buyer notification

### Admin Flow

1. `AdminLoginView` signs in with Firebase Auth
2. App verifies `UserProfile.isAdmin == true`
3. `AdminDashboardView` loads:
   - Products
   - Orders
   - Coupons
   - Deals
4. Admin actions can:
   - create or edit catalog content
   - update order status
   - create buyer-facing notifications
   - trigger local promo reminders in demo mode

## Project Structure

```text
ELORA/
|-- README.md
|-- ELORAApp.swift
|-- ContentView.swift
|-- GoogleService-Info.plist
|-- ELORA.entitlements
|-- App/
|   `-- AppRouter.swift
|-- Domain/
|   |-- Models/
|   `-- Protocols/
|-- Data/
|   |-- Repositories/
|   |-- Services/
|   `-- Seeders/
|-- Presentation/
|   |-- Admin/
|   |-- Auth/
|   |-- Cart/
|   |-- Checkout/
|   |-- Components/
|   |-- Favorites/
|   |-- Home/
|   |-- Profile/
|   |-- Shop/
|   `-- Theme/
|-- Assets.xcassets/
|-- Preview Content/
|-- ELORATests/
`-- ELORAUITests/
```

## Important Files

- `ELORA/ELORAApp.swift`
  App entry point, Firebase setup, session resolution, notification startup, and initial routing
- `ELORA/App/AppRouter.swift`
  Main customer navigation shell and tab routing
- `ELORA/Presentation/Auth/AuthViewModel.swift`
  Authentication logic and Firebase user-session listener
- `ELORA/Presentation/Checkout/CheckoutViewModel.swift`
  Checkout state machine and order creation workflow
- `ELORA/Presentation/Admin/AdminViewModel.swift`
  Admin CRUD and order-management coordinator
- `ELORA/Data/Repositories/`
  Firebase-backed implementations of repository protocols
- `ELORA/Data/Services/`
  Currency, location, notifications, API, and payment services

## State Management

The project uses the following Swift property wrappers:

- `@StateObject` for view-owned long-lived observable state
- `@ObservedObject` for shared objects passed from parent views
- `@Binding` for child-to-parent state updates
- `@State` for local view-only UI state
- `@Environment(\\.dismiss)` for modal dismissal
- `@Published` in view models and services
- `@DocumentID` in Firestore-backed domain models
- `@UIApplicationDelegateAdaptor` in `ELORAApp.swift`

`@EnvironmentObject` is not used in this project.

## Firebase Data Model

Main collections and subcollections used by the app:

- `users`
  - user profile
  - `cart` subcollection
  - `favorites` subcollection
- `products`
  - product documents
  - `reviews` subcollection
- `orders`
- `coupons`
- `deals`
- `notifications`

## Getting Started

### Prerequisites

- macOS with Xcode installed
- iOS Simulator or physical iPhone
- Firebase project configured for iOS
- `GoogleService-Info.plist` added to the app target

### Run the App

1. Open `ELORA.xcodeproj` in Xcode
2. Let Swift Package Manager resolve dependencies
3. Confirm Firebase packages are available
4. Confirm `GoogleService-Info.plist` is included in the `ELORA` target
5. Select an iPhone simulator or device
6. Build and run

## Demo Notes

- The app seeds sample products, deals, and coupons on first local launch
- Guests can browse but are required to sign in before placing an order
- Checkout currently uses a mock payment gateway rather than a live Stripe flow
- Admin access depends on a Firestore user profile with `isAdmin = true`

## Limitations

- Test targets are mostly template placeholders and need stronger automated coverage
- The mock payment gateway is designed for demos, not production use
- Seeder behavior is device-local and may duplicate data in a shared backend if used from multiple fresh installs

## Additional Documentation

- `ELORA_CODEBASE_REVIEW.txt` contains a detailed file-by-file codebase walkthrough, file connections, workflow tracing, and property-wrapper analysis

## Credits

ELORA is structured as a context-aware e-commerce lab/project app focused on clean SwiftUI architecture, Firebase integration, and end-to-end flow demonstration.
