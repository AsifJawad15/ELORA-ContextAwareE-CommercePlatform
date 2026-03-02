import SwiftUI

// MARK: - Colors
enum AppColors {
    static let background   = Color.black
    static let surface      = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let card         = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let text         = Color.white
    static let textSecondary = Color.white.opacity(0.75)
    static let muted        = Color.white.opacity(0.5)
    static let line         = Color.white.opacity(0.18)
    static let accent       = Color(red: 0.86, green: 0.53, blue: 0.38) // Copper/Rose Gold
    static let error        = Color(red: 0.90, green: 0.30, blue: 0.30)
    static let success      = Color(red: 0.30, green: 0.78, blue: 0.47)
    static let warning      = Color(red: 0.95, green: 0.77, blue: 0.26)

    // Light variants for hero sections
    static let lightBg      = Color.white
    static let lightText    = Color.black
    static let lightMuted   = Color.black.opacity(0.55)
}

// MARK: - Typography
enum AppFonts {
    static let tenorSans = "Tenor Sans"

    static func tenor(_ size: CGFloat) -> Font {
        .custom(tenorSans, size: size)
    }

    static var largeTitle: Font { .custom(tenorSans, size: 34) }
    static var title: Font { .custom(tenorSans, size: 28) }
    static var title2: Font { .custom(tenorSans, size: 22) }
    static var title3: Font { .custom(tenorSans, size: 20) }
    static var headline: Font { .custom(tenorSans, size: 17) }
    static var body: Font { .custom(tenorSans, size: 16) }
    static var callout: Font { .custom(tenorSans, size: 15) }
    static var subheadline: Font { .custom(tenorSans, size: 14) }
    static var footnote: Font { .custom(tenorSans, size: 13) }
    static var caption: Font { .custom(tenorSans, size: 12) }
    static var caption2: Font { .custom(tenorSans, size: 11) }

    // System font fallbacks (if Tenor Sans not bundled)
    static func systemBody(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 16, weight: weight)
    }
}

// MARK: - Spacing
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum AppRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Button Styles
struct EloraPrimaryButton: ButtonStyle {
    var isFullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(AppColors.accent)
            .cornerRadius(AppRadius.full)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct EloraSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .stroke(AppColors.accent, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct EloraOutlineButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.footnote)
            .foregroundColor(AppColors.text)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .stroke(AppColors.line, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
