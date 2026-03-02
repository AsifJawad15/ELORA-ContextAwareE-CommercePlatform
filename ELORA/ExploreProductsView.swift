//
//  ExploreProductsView.swift
//  ELORA
//
//  Created by macos on 1/3/26.
//
import SwiftUI

struct ExploreProductsView: View {

    @StateObject private var vm = ProductViewModel()

    enum Category: String, CaseIterable {
        case all = "All"
        case apparel = "Apparel"
        case dress = "Dress"
        case tshirt = "Tshirt"
        case bag = "Bag"
    }

    @State private var selected: Category = .all

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                DiamondDivider()
                    .padding(.top, 18)

                CategoryTabs(selected: $selected)
                    .padding(.top, 18)

                ScrollView {
                    if vm.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading...")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.custom("Tenor Sans", size: 14))
                        }
                        .padding(.top, 40)
                    } else if let msg = vm.errorMessage {
                        VStack(spacing: 12) {
                            Text("⚠️ \(msg)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

                            Button("Retry") {
                                vm.fetchProducts()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(vm.products) { p in
                                ProductTileRemote(
                                    imageUrl: p.imageUrl,
                                    name: p.name,
                                    price: p.price
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 24)

                        HStack {
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            vm.fetchProducts()
        }
    }
}

// MARK: - UI pieces

private struct DiamondDivider: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1)
            Diamond()
                .fill(Color.white.opacity(0.35))
                .frame(width: 10, height: 10)
            Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1)
        }
        .padding(.horizontal, 30)
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct CategoryTabs: View {
    @Binding var selected: ExploreProductsView.Category

    var body: some View {
        HStack(spacing: 26) {
            ForEach(ExploreProductsView.Category.allCases, id: \.self) { cat in
                VStack(spacing: 6) {
                    Text(cat.rawValue)
                        .font(.custom("Tenor Sans", size: 18))
                        .foregroundColor(cat == selected ? Color.white.opacity(0.9) : Color.white.opacity(0.55))
                        .onTapGesture { selected = cat }

                    if cat == selected {
                        Diamond()
                            .fill(Color(red: 0.86, green: 0.53, blue: 0.38))
                            .frame(width: 8, height: 8)
                    } else {
                        Color.clear.frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct ProductTileRemote: View {
    let imageUrl: String
    let name: String
    let price: Double

    var body: some View {
        VStack(spacing: 10) {

            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        // Alt-text fallback
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.35))
                            Text(name)
                                .font(.custom("Tenor Sans", size: 12))
                                .foregroundColor(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.06))
                    case .empty:
                        Color.white.opacity(0.06).overlay(ProgressView())
                    @unknown default:
                        Color.white.opacity(0.06)
                    }
                }
            }
            .frame(height: 210)
            .clipped()

            Text(name)
                .font(.custom("Tenor Sans", size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)

            Text("$\(Int(price))")
                .font(.custom("Tenor Sans", size: 20))
                .foregroundColor(Color(red: 0.86, green: 0.53, blue: 0.38))
        }
    }
}
