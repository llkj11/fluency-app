import XCTest
@testable import Fluency

final class ThemeManagerTests: XCTestCase {
    
    // MARK: - Default Theme Tests
    
    func testDefaultThemeIsAurora() {
        // Create a fresh UserDefaults to test without persisted data
        let testDefaults = UserDefaults(suiteName: "ThemeManagerTestDefaults")!
        testDefaults.removePersistentDomain(forName: "ThemeManagerTestDefaults")
        
        let manager = ThemeManager(userDefaults: testDefaults, key: "testTheme")
        XCTAssertEqual(manager.currentTheme, .aurora, "Default theme should be Aurora")
    }
    
    // MARK: - Theme Persistence Tests
    
    func testThemePersistsToUserDefaults() {
        let testDefaults = UserDefaults(suiteName: "ThemeManagerTestPersist")!
        testDefaults.removePersistentDomain(forName: "ThemeManagerTestPersist")
        
        // Create manager and change theme
        let manager = ThemeManager(userDefaults: testDefaults, key: "testTheme")
        manager.currentTheme = .midnight
        
        // Verify it was saved
        let savedValue = testDefaults.string(forKey: "testTheme")
        XCTAssertEqual(savedValue, "Midnight", "Theme should be saved to UserDefaults")
    }
    
    func testThemeLoadsFromUserDefaults() {
        let testDefaults = UserDefaults(suiteName: "ThemeManagerTestLoad")!
        testDefaults.removePersistentDomain(forName: "ThemeManagerTestLoad")
        
        // Pre-set a theme value
        testDefaults.set("Ember", forKey: "loadTestTheme")
        
        // Create manager and verify it loads the saved theme
        let manager = ThemeManager(userDefaults: testDefaults, key: "loadTestTheme")
        XCTAssertEqual(manager.currentTheme, .ember, "Theme should load from UserDefaults")
    }
    
    // MARK: - Color Token Tests
    
    func testAllThemesReturnValidColors() {
        let manager = ThemeManager()
        
        for theme in AppTheme.allCases {
            manager.currentTheme = theme
            let colors = manager.colors
            
            // Verify all color properties are accessible (non-optional)
            XCTAssertNotNil(colors.primary, "\(theme.rawValue) should have a primary color")
            XCTAssertNotNil(colors.secondary, "\(theme.rawValue) should have a secondary color")
            XCTAssertNotNil(colors.accent, "\(theme.rawValue) should have an accent color")
            XCTAssertNotNil(colors.gradientStart, "\(theme.rawValue) should have a gradientStart color")
            XCTAssertNotNil(colors.gradientMiddle, "\(theme.rawValue) should have a gradientMiddle color")
            XCTAssertNotNil(colors.gradientEnd, "\(theme.rawValue) should have a gradientEnd color")
        }
    }
    
    // MARK: - Theme Enum Tests
    
    func testAllThemesHaveRawValues() {
        XCTAssertEqual(AppTheme.aurora.rawValue, "Aurora")
        XCTAssertEqual(AppTheme.midnight.rawValue, "Midnight")
        XCTAssertEqual(AppTheme.ember.rawValue, "Ember")
        XCTAssertEqual(AppTheme.forest.rawValue, "Forest")
        XCTAssertEqual(AppTheme.monochrome.rawValue, "Monochrome")
        XCTAssertEqual(AppTheme.sakura.rawValue, "Sakura")
    }
    
    func testAllThemesHaveDescriptions() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.description.isEmpty, "\(theme.rawValue) should have a description")
        }
    }
    
    func testAllThemesHaveIcons() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.icon.isEmpty, "\(theme.rawValue) should have an icon")
        }
    }
    
    // MARK: - Font Tests
    
    func testAllThemesReturnValidFonts() {
        let manager = ThemeManager()
        
        for theme in AppTheme.allCases {
            manager.currentTheme = theme
            let fonts = manager.fonts
            
            // Verify font methods return valid fonts
            XCTAssertNotNil(fonts.title(), "\(theme.rawValue) should return a title font")
            XCTAssertNotNil(fonts.headline(), "\(theme.rawValue) should return a headline font")
            XCTAssertNotNil(fonts.body(), "\(theme.rawValue) should return a body font")
            XCTAssertNotNil(fonts.caption(), "\(theme.rawValue) should return a caption font")
        }
    }
    
    // MARK: - Theme Switching Tests
    
    func testThemeSwitchingUpdatesColors() {
        let manager = ThemeManager()
        
        manager.currentTheme = .aurora
        let auroraGradientStart = manager.colors.gradientStart
        
        manager.currentTheme = .ember
        let emberGradientStart = manager.colors.gradientStart
        
        // Colors should be different between themes
        XCTAssertNotEqual(
            "\(auroraGradientStart)",
            "\(emberGradientStart)",
            "Different themes should have different gradient colors"
        )
    }
}
