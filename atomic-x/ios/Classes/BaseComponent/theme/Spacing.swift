import SwiftUI

public let SpacingScheme = SemanticSpacingScheme(
    iconTextSpacing: Spacings.Spacing4,
    smallSpacing: Spacings.Spacing8,
    iconIconSpacing: Spacings.Spacing12,
    bubbleSpacing: Spacings.Spacing16,
    contentSpacing: Spacings.Spacing20,
    normalSpacing: Spacings.Spacing24,
    titleSpacing: Spacings.Spacing32,
    cardSpacing: Spacings.Spacing40,
    largeSpacing: Spacings.Spacing56,
    maxSpacing: Spacings.Spacing72
)

public struct SemanticSpacingScheme {
    public let iconTextSpacing: Int
    public let smallSpacing: Int
    public let iconIconSpacing: Int
    public let bubbleSpacing: Int
    public let contentSpacing: Int
    public let normalSpacing: Int
    public let titleSpacing: Int
    public let cardSpacing: Int
    public let largeSpacing: Int
    public let maxSpacing: Int
}

private enum Spacings {
    static let Spacing4 = 4
    static let Spacing8 = 8
    static let Spacing12 = 12
    static let Spacing16 = 16
    static let Spacing20 = 20
    static let Spacing24 = 24
    static let Spacing32 = 32
    static let Spacing40 = 40
    static let Spacing56 = 56
    static let Spacing72 = 72
}
