import XCTest
@testable import ChattySDK

final class ChattyDesignTokensTests: XCTestCase {
    // MARK: - chattyNormalizeWidgetStyle

    func testNormalizeReturnsMinimalForNilOrEmpty() {
        XCTAssertEqual(chattyNormalizeWidgetStyle(nil), "minimal")
        XCTAssertEqual(chattyNormalizeWidgetStyle(""), "minimal")
    }

    func testNormalizeReturnsKnownDesignIdUnchanged() {
        for id in chattyDesignTokens.keys {
            XCTAssertEqual(chattyNormalizeWidgetStyle(id), id)
        }
    }

    func testNormalizeExtractsFirstColonSegment() {
        XCTAssertEqual(chattyNormalizeWidgetStyle("corporate:#112233:rounded"), "corporate")
        XCTAssertEqual(chattyNormalizeWidgetStyle("dark-sleek:#000:square"), "dark-sleek")
    }

    func testNormalizeMapsEveryLegacyStyleToACurrentDesign() {
        let legacyToExpected: [String: String] = [
            "liquid": "glassmorphism",
            "neumorphism": "corporate",
            "claymorphism": "playful",
            "bento": "minimal",
            "brutalism": "neubrutalism",
            "retro": "dark-sleek",
            "aurora": "gradient-glow",
            "minimalist": "minimal",
            "elevated": "corporate",
            "frosted": "glassmorphism",
            "bold": "gradient-glow",
            "contrast": "dark-sleek",
        ]
        for (legacy, expected) in legacyToExpected {
            XCTAssertEqual(chattyNormalizeWidgetStyle(legacy), expected, "legacy id \(legacy) should map to \(expected)")
            XCTAssertNotNil(chattyDesignTokens[expected], "mapped id \(expected) must itself be a real design")
        }
    }

    func testNormalizeFallsBackToMinimalForUnknownId() {
        XCTAssertEqual(chattyNormalizeWidgetStyle("some-future-design-nobody-has-heard-of"), "minimal")
    }

    // MARK: - chattyLogoBgColor

    func testLogoBgColorNilWhenRawIsNil() {
        XCTAssertNil(chattyLogoBgColor(nil))
    }

    func testLogoBgColorNilWhenSecondSegmentMissingOrEmpty() {
        XCTAssertNil(chattyLogoBgColor("minimal"))
        XCTAssertNil(chattyLogoBgColor("minimal:"))
    }

    func testLogoBgColorPresentWhenSecondSegmentNonEmpty() {
        XCTAssertNotNil(chattyLogoBgColor("minimal:#ff0000:bubble"))
        XCTAssertNotNil(chattyLogoBgColor("minimal:#ff0000"))
    }

    // MARK: - design token catalog

    func testAllTenDesignsArePresent() {
        let expected: Set<String> = [
            "minimal", "playful", "corporate", "dark-sleek", "gradient-glow",
            "glassmorphism", "ecommerce", "healthcare-calm", "neubrutalism", "luxury-editorial",
        ]
        XCTAssertEqual(Set(chattyDesignTokens.keys), expected)
    }

    func testGradientGlowHeaderColorsHasTwoStops() {
        XCTAssertEqual(chattyGradientGlowHeaderColors.count, 2)
    }
}
