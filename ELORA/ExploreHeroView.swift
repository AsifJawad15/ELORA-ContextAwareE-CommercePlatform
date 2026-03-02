//
//  ExploreHeroView.swift
//  ELORA
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct ExploreHeroView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                TopBarLight()

                ZStack(alignment: .bottom) {
                    Image("cover")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 560)
                        .clipped()

                    VStack(spacing: 16) {
                        Text("LUXURY\nFASHION\n& ACCESSORIES")
                            .font(.custom("Tenor Sans", size: 42))
                            .foregroundColor(.black.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 60)

                        Button(action: {}) {
                            Text("EXPLORE COLLECTION")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 18)

                        PageDots(count: 5, active: 1)
                            .padding(.bottom, 18)
                    }
                }

                Spacer()
            }
        }
    }
}

struct TopBarLight: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
            }

            Spacer()

            Text("Open\nFashion")
                .font(.custom("Tenor Sans", size: 18))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(-2)

            Spacer()

            HStack(spacing: 18) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }

                Button(action: {}) {
                    Image(systemName: "bag")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.85))
    }
}

struct PageDots: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == active ? Color.black.opacity(0.8) : Color.black.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
