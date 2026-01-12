import SwiftUI

// MARK: - Theme Enum

enum AppTheme: String, CaseIterable, Identifiable {
    case aurora = "Aurora"
    case midnight = "Midnight"
    case ember = "Ember"
    case forest = "Forest"
    case monochrome = "Monochrome"
    case sakura = "Sakura"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .aurora: return "Vibrant purple to cyan gradient"
        case .midnight: return "Deep indigo and electric blue"
        case .ember: return "Warm orange and deep red"
        case .forest: return "Emerald green and teal"
        case .monochrome: return "Minimal grayscale"
        case .sakura: return "Soft pink and lavender"
        }
    }
    
    var icon: String {
        switch self {
        case .aurora: return "sparkles"
        case .midnight: return "moon.stars.fill"
        case .ember: return "flame.fill"
        case .forest: return "leaf.fill"
        case .monochrome: return "circle.lefthalf.filled"
        case .sakura: return "cherry.blossom.fill"
        }
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    // Primary gradient colors
    let primary: Color
    let secondary: Color
    let accent: Color
    let gradientStart: Color
    let gradientMiddle: Color
    let gradientEnd: Color
    
    // Window & Background colors
    let windowBackground: Color
    let surfaceBackground: Color
    let cardBackground: Color
    let cardBackgroundOpacity: Double
    
    // Text colors
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    
    // Icon colors for stat cards
    let iconWords: Color
    let iconTranscriptions: Color
    let iconTime: Color
    let iconSaved: Color
    
    // Tab & Navigation
    let tabSelected: Color
    let tabUnselected: Color
    let tabBackground: Color
    
    // Computed gradients
    var headerGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMiddle, gradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [windowBackground, surfaceBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var fullWindowGradient: LinearGradient {
        LinearGradient(
            colors: [windowBackground.opacity(0.95), surfaceBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Theme Fonts

struct ThemeFonts {
    let titleDesign: Font.Design
    let bodyDesign: Font.Design
    
    func title(size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: titleDesign)
    }
    
    func headline(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: titleDesign)
    }
    
    func body(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: bodyDesign)
    }
    
    func caption(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: bodyDesign)
    }
    
    func statValue(size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: titleDesign)
    }
}

// MARK: - Theme Styles

struct ThemeStyles {
    let cornerRadius: CGFloat
    let cardShadowRadius: CGFloat
    let cardPadding: CGFloat
    
    static let standard = ThemeStyles(
        cornerRadius: 12,
        cardShadowRadius: 4,
        cardPadding: 16
    )
    
    static let compact = ThemeStyles(
        cornerRadius: 8,
        cardShadowRadius: 2,
        cardPadding: 10
    )
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    private let userDefaults: UserDefaults
    private let themeKey: String
    
    var currentTheme: AppTheme {
        didSet {
            userDefaults.set(currentTheme.rawValue, forKey: themeKey)
        }
    }
    
    init() {
        self.userDefaults = .standard
        self.themeKey = "selectedTheme"
        
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .aurora
        }
    }
    
    // For testing - allows injecting a custom UserDefaults
    init(userDefaults: UserDefaults, key: String = "selectedTheme") {
        self.userDefaults = userDefaults
        self.themeKey = key
        
        if let savedTheme = userDefaults.string(forKey: key),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .aurora
        }
    }
    
    var colors: ThemeColors {
        switch currentTheme {
        case .aurora:
            // Vibrant purple-blue-cyan with dark background
            return ThemeColors(
                primary: .purple,
                secondary: .blue,
                accent: .cyan,
                gradientStart: .purple,
                gradientMiddle: .blue,
                gradientEnd: .cyan,
                windowBackground: Color(red: 0.08, green: 0.06, blue: 0.15),
                surfaceBackground: Color(red: 0.12, green: 0.08, blue: 0.2),
                cardBackground: Color(red: 0.15, green: 0.1, blue: 0.25),
                cardBackgroundOpacity: 0.9,
                textPrimary: .white,
                textSecondary: Color(white: 0.75),
                textMuted: Color(white: 0.5),
                iconWords: .blue,
                iconTranscriptions: .purple,
                iconTime: .orange,
                iconSaved: .green,
                tabSelected: .cyan,
                tabUnselected: Color(white: 0.5),
                tabBackground: Color(red: 0.1, green: 0.08, blue: 0.18)
            )
        case .midnight:
            // Deep indigo with electric blue accents - truly dark
            return ThemeColors(
                primary: Color(red: 0.2, green: 0.2, blue: 0.5),
                secondary: Color(red: 0.1, green: 0.4, blue: 0.8),
                accent: Color(red: 0.3, green: 0.6, blue: 1.0),
                gradientStart: Color(red: 0.15, green: 0.15, blue: 0.4),
                gradientMiddle: Color(red: 0.1, green: 0.3, blue: 0.7),
                gradientEnd: Color(red: 0.2, green: 0.5, blue: 0.9),
                windowBackground: Color(red: 0.02, green: 0.02, blue: 0.08),
                surfaceBackground: Color(red: 0.05, green: 0.05, blue: 0.12),
                cardBackground: Color(red: 0.08, green: 0.1, blue: 0.2),
                cardBackgroundOpacity: 0.95,
                textPrimary: Color(red: 0.9, green: 0.92, blue: 1.0),
                textSecondary: Color(red: 0.6, green: 0.65, blue: 0.8),
                textMuted: Color(red: 0.4, green: 0.45, blue: 0.6),
                iconWords: Color(red: 0.3, green: 0.6, blue: 1.0),
                iconTranscriptions: Color(red: 0.5, green: 0.4, blue: 0.9),
                iconTime: Color(red: 0.4, green: 0.7, blue: 0.9),
                iconSaved: Color(red: 0.3, green: 0.8, blue: 0.7),
                tabSelected: Color(red: 0.3, green: 0.6, blue: 1.0),
                tabUnselected: Color(red: 0.4, green: 0.45, blue: 0.6),
                tabBackground: Color(red: 0.03, green: 0.03, blue: 0.1)
            )
        case .ember:
            // Warm fire colors with dark charcoal background
            return ThemeColors(
                primary: .orange,
                secondary: Color(red: 0.9, green: 0.3, blue: 0.1),
                accent: .red,
                gradientStart: .orange,
                gradientMiddle: Color(red: 0.95, green: 0.4, blue: 0.2),
                gradientEnd: Color(red: 0.8, green: 0.2, blue: 0.1),
                windowBackground: Color(red: 0.1, green: 0.06, blue: 0.04),
                surfaceBackground: Color(red: 0.15, green: 0.08, blue: 0.05),
                cardBackground: Color(red: 0.2, green: 0.1, blue: 0.08),
                cardBackgroundOpacity: 0.9,
                textPrimary: Color(red: 1.0, green: 0.95, blue: 0.9),
                textSecondary: Color(red: 0.85, green: 0.7, blue: 0.6),
                textMuted: Color(red: 0.6, green: 0.5, blue: 0.4),
                iconWords: Color(red: 1.0, green: 0.6, blue: 0.2),
                iconTranscriptions: Color(red: 0.9, green: 0.4, blue: 0.2),
                iconTime: Color(red: 1.0, green: 0.8, blue: 0.3),
                iconSaved: Color(red: 0.8, green: 0.9, blue: 0.3),
                tabSelected: .orange,
                tabUnselected: Color(red: 0.6, green: 0.5, blue: 0.4),
                tabBackground: Color(red: 0.12, green: 0.07, blue: 0.04)
            )
        case .forest:
            // Natural greens and teals with earthy background
            return ThemeColors(
                primary: Color(red: 0.2, green: 0.6, blue: 0.4),
                secondary: .teal,
                accent: Color(red: 0.1, green: 0.7, blue: 0.5),
                gradientStart: Color(red: 0.15, green: 0.5, blue: 0.35),
                gradientMiddle: .teal,
                gradientEnd: Color(red: 0.2, green: 0.65, blue: 0.55),
                windowBackground: Color(red: 0.04, green: 0.1, blue: 0.08),
                surfaceBackground: Color(red: 0.06, green: 0.14, blue: 0.1),
                cardBackground: Color(red: 0.08, green: 0.18, blue: 0.14),
                cardBackgroundOpacity: 0.9,
                textPrimary: Color(red: 0.9, green: 1.0, blue: 0.95),
                textSecondary: Color(red: 0.65, green: 0.8, blue: 0.7),
                textMuted: Color(red: 0.45, green: 0.6, blue: 0.5),
                iconWords: .teal,
                iconTranscriptions: Color(red: 0.3, green: 0.7, blue: 0.5),
                iconTime: Color(red: 0.6, green: 0.8, blue: 0.4),
                iconSaved: Color(red: 0.4, green: 0.9, blue: 0.6),
                tabSelected: Color(red: 0.2, green: 0.8, blue: 0.6),
                tabUnselected: Color(red: 0.45, green: 0.6, blue: 0.5),
                tabBackground: Color(red: 0.05, green: 0.12, blue: 0.09)
            )
        case .monochrome:
            // Clean grayscale with subtle blue tint
            return ThemeColors(
                primary: Color(white: 0.4),
                secondary: Color(white: 0.55),
                accent: Color(white: 0.7),
                gradientStart: Color(white: 0.45),
                gradientMiddle: Color(white: 0.55),
                gradientEnd: Color(white: 0.65),
                windowBackground: Color(white: 0.05),
                surfaceBackground: Color(white: 0.08),
                cardBackground: Color(white: 0.12),
                cardBackgroundOpacity: 0.95,
                textPrimary: Color(white: 0.95),
                textSecondary: Color(white: 0.7),
                textMuted: Color(white: 0.45),
                iconWords: Color(white: 0.7),
                iconTranscriptions: Color(white: 0.6),
                iconTime: Color(white: 0.65),
                iconSaved: Color(white: 0.75),
                tabSelected: Color(white: 0.9),
                tabUnselected: Color(white: 0.5),
                tabBackground: Color(white: 0.06)
            )
        case .sakura:
            // Soft pink and lavender with light blush background
            return ThemeColors(
                primary: Color(red: 1.0, green: 0.7, blue: 0.8),
                secondary: Color(red: 0.8, green: 0.6, blue: 0.9),
                accent: Color(red: 0.9, green: 0.5, blue: 0.7),
                gradientStart: Color(red: 1.0, green: 0.75, blue: 0.85),
                gradientMiddle: Color(red: 0.9, green: 0.65, blue: 0.85),
                gradientEnd: Color(red: 0.8, green: 0.6, blue: 0.9),
                windowBackground: Color(red: 0.15, green: 0.08, blue: 0.12),
                surfaceBackground: Color(red: 0.2, green: 0.1, blue: 0.15),
                cardBackground: Color(red: 0.25, green: 0.12, blue: 0.18),
                cardBackgroundOpacity: 0.9,
                textPrimary: Color(red: 1.0, green: 0.95, blue: 0.97),
                textSecondary: Color(red: 0.85, green: 0.75, blue: 0.8),
                textMuted: Color(red: 0.6, green: 0.5, blue: 0.55),
                iconWords: Color(red: 0.9, green: 0.6, blue: 0.75),
                iconTranscriptions: Color(red: 0.8, green: 0.5, blue: 0.85),
                iconTime: Color(red: 1.0, green: 0.7, blue: 0.6),
                iconSaved: Color(red: 0.7, green: 0.9, blue: 0.75),
                tabSelected: Color(red: 1.0, green: 0.7, blue: 0.8),
                tabUnselected: Color(red: 0.6, green: 0.5, blue: 0.55),
                tabBackground: Color(red: 0.17, green: 0.09, blue: 0.13)
            )
        }
    }
    
    var fonts: ThemeFonts {
        switch currentTheme {
        case .aurora, .midnight, .sakura:
            return ThemeFonts(titleDesign: .rounded, bodyDesign: .rounded)
        case .ember:
            return ThemeFonts(titleDesign: .default, bodyDesign: .default)
        case .forest:
            return ThemeFonts(titleDesign: .serif, bodyDesign: .default)
        case .monochrome:
            return ThemeFonts(titleDesign: .monospaced, bodyDesign: .monospaced)
        }
    }
    
    var styles: ThemeStyles {
        .standard
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func themed(_ themeManager: ThemeManager) -> some View {
        self.environment(\.themeManager, themeManager)
    }
}
