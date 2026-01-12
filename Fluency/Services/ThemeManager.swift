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
    let primary: Color
    let secondary: Color
    let accent: Color
    let gradientStart: Color
    let gradientMiddle: Color
    let gradientEnd: Color
    let cardBackground: Color
    let cardBackgroundOpacity: Double
    
    var headerGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMiddle, gradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart.opacity(0.1), gradientEnd.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
            return ThemeColors(
                primary: .purple,
                secondary: .blue,
                accent: .cyan,
                gradientStart: .purple,
                gradientMiddle: .blue,
                gradientEnd: .cyan,
                cardBackground: .purple,
                cardBackgroundOpacity: 0.1
            )
        case .midnight:
            return ThemeColors(
                primary: Color(red: 0.2, green: 0.2, blue: 0.5),
                secondary: Color(red: 0.1, green: 0.4, blue: 0.8),
                accent: Color(red: 0.3, green: 0.6, blue: 1.0),
                gradientStart: Color(red: 0.15, green: 0.15, blue: 0.4),
                gradientMiddle: Color(red: 0.1, green: 0.3, blue: 0.7),
                gradientEnd: Color(red: 0.2, green: 0.5, blue: 0.9),
                cardBackground: Color(red: 0.1, green: 0.2, blue: 0.4),
                cardBackgroundOpacity: 0.15
            )
        case .ember:
            return ThemeColors(
                primary: .orange,
                secondary: Color(red: 0.9, green: 0.3, blue: 0.1),
                accent: .red,
                gradientStart: .orange,
                gradientMiddle: Color(red: 0.95, green: 0.4, blue: 0.2),
                gradientEnd: Color(red: 0.8, green: 0.2, blue: 0.1),
                cardBackground: .orange,
                cardBackgroundOpacity: 0.12
            )
        case .forest:
            return ThemeColors(
                primary: Color(red: 0.2, green: 0.6, blue: 0.4),
                secondary: .teal,
                accent: Color(red: 0.1, green: 0.7, blue: 0.5),
                gradientStart: Color(red: 0.15, green: 0.5, blue: 0.35),
                gradientMiddle: .teal,
                gradientEnd: Color(red: 0.2, green: 0.65, blue: 0.55),
                cardBackground: Color(red: 0.2, green: 0.55, blue: 0.4),
                cardBackgroundOpacity: 0.1
            )
        case .monochrome:
            return ThemeColors(
                primary: Color(white: 0.3),
                secondary: Color(white: 0.5),
                accent: Color(red: 0.4, green: 0.5, blue: 0.6),
                gradientStart: Color(white: 0.35),
                gradientMiddle: Color(white: 0.45),
                gradientEnd: Color(white: 0.55),
                cardBackground: Color(white: 0.4),
                cardBackgroundOpacity: 0.08
            )
        case .sakura:
            return ThemeColors(
                primary: Color(red: 1.0, green: 0.7, blue: 0.8),
                secondary: Color(red: 0.8, green: 0.6, blue: 0.9),
                accent: Color(red: 0.9, green: 0.5, blue: 0.7),
                gradientStart: Color(red: 1.0, green: 0.75, blue: 0.85),
                gradientMiddle: Color(red: 0.9, green: 0.65, blue: 0.85),
                gradientEnd: Color(red: 0.8, green: 0.6, blue: 0.9),
                cardBackground: Color(red: 1.0, green: 0.7, blue: 0.8),
                cardBackgroundOpacity: 0.12
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
