//
//  Theme.swift
//  ELORA
//
//  Created by macos on 1/3/26.
//

import SwiftUI

enum Theme {
    enum Colors {
        static let bg = Color.black
        static let surface = Color.black
        static let text = Color.white
        static let muted = Color.white.opacity(0.75)
        static let line = Color.white.opacity(0.18)

        
        static let accent = Color(red: 0.86, green: 0.53, blue: 0.38)
    }

    enum FontName {
        static let tenorSans = "Tenor Sans"
    }

    enum Typography {
        static func title(_ size: CGFloat) -> Font {
            .custom(FontName.tenorSans, size: size)
        }
        static func body(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func label(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }
    }
}
