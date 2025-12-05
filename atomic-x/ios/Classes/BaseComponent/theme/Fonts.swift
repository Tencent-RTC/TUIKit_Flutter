import SwiftUI

public let FontScheme = SemanticFontScheme(
    title1Bold: Fonts.Bold40,
    title2Bold: Fonts.Bold36,
    title3Bold: Fonts.Bold34,
    title4Bold: Fonts.Bold32,
    body1Bold: Fonts.Bold28,
    body2Bold: Fonts.Bold24,
    body3Bold: Fonts.Bold20,
    body4Bold: Fonts.Bold18,
    caption1Bold: Fonts.Bold16,
    caption2Bold: Fonts.Bold14,
    caption3Bold: Fonts.Bold12,
    caption4Bold: Fonts.Bold10,
    title1Medium: Fonts.Medium40,
    title2Medium: Fonts.Medium36,
    title3Medium: Fonts.Medium34,
    title4Medium: Fonts.Medium32,
    body1Medium: Fonts.Medium28,
    body2Medium: Fonts.Medium24,
    body3Medium: Fonts.Medium20,
    body4Medium: Fonts.Medium18,
    caption1Medium: Fonts.Medium16,
    caption2Medium: Fonts.Medium14,
    caption3Medium: Fonts.Medium12,
    caption4Medium: Fonts.Medium10,
    title1Regular: Fonts.Regular40,
    title2Regular: Fonts.Regular36,
    title3Regular: Fonts.Regular34,
    title4Regular: Fonts.Regular32,
    body1Regular: Fonts.Regular28,
    body2Regular: Fonts.Regular24,
    body3Regular: Fonts.Regular20,
    body4Regular: Fonts.Regular18,
    caption1Regular: Fonts.Regular16,
    caption2Regular: Fonts.Regular14,
    caption3Regular: Fonts.Regular12,
    caption4Regular: Fonts.Regular10
)

public struct SemanticFontScheme {
    public let title1Bold: Font
    public let title2Bold: Font
    public let title3Bold: Font
    public let title4Bold: Font
    public let body1Bold: Font
    public let body2Bold: Font
    public let body3Bold: Font
    public let body4Bold: Font
    public let caption1Bold: Font
    public let caption2Bold: Font
    public let caption3Bold: Font
    public let caption4Bold: Font
    public let title1Medium: Font
    public let title2Medium: Font
    public let title3Medium: Font
    public let title4Medium: Font
    public let body1Medium: Font
    public let body2Medium: Font
    public let body3Medium: Font
    public let body4Medium: Font
    public let caption1Medium: Font
    public let caption2Medium: Font
    public let caption3Medium: Font
    public let caption4Medium: Font
    public let title1Regular: Font
    public let title2Regular: Font
    public let title3Regular: Font
    public let title4Regular: Font
    public let body1Regular: Font
    public let body2Regular: Font
    public let body3Regular: Font
    public let body4Regular: Font
    public let caption1Regular: Font
    public let caption2Regular: Font
    public let caption3Regular: Font
    public let caption4Regular: Font
}

private enum Fonts {
    static let Bold40 = Font.system(size: 40, weight: .bold)
    static let Bold36 = Font.system(size: 36, weight: .bold)
    static let Bold34 = Font.system(size: 34, weight: .bold)
    static let Bold32 = Font.system(size: 32, weight: .bold)
    static let Bold28 = Font.system(size: 28, weight: .bold)
    static let Bold24 = Font.system(size: 24, weight: .bold)
    static let Bold20 = Font.system(size: 20, weight: .bold)
    static let Bold18 = Font.system(size: 18, weight: .bold)
    static let Bold16 = Font.system(size: 16, weight: .bold)
    static let Bold14 = Font.system(size: 14, weight: .bold)
    static let Bold12 = Font.system(size: 12, weight: .bold)
    static let Bold10 = Font.system(size: 10, weight: .bold)
    static let Medium40 = Font.system(size: 40, weight: .medium)
    static let Medium36 = Font.system(size: 36, weight: .medium)
    static let Medium34 = Font.system(size: 34, weight: .medium)
    static let Medium32 = Font.system(size: 32, weight: .medium)
    static let Medium28 = Font.system(size: 28, weight: .medium)
    static let Medium24 = Font.system(size: 24, weight: .medium)
    static let Medium20 = Font.system(size: 20, weight: .medium)
    static let Medium18 = Font.system(size: 18, weight: .medium)
    static let Medium16 = Font.system(size: 16, weight: .medium)
    static let Medium14 = Font.system(size: 14, weight: .medium)
    static let Medium12 = Font.system(size: 12, weight: .medium)
    static let Medium10 = Font.system(size: 10, weight: .medium)
    static let Regular40 = Font.system(size: 40, weight: .regular)
    static let Regular36 = Font.system(size: 36, weight: .regular)
    static let Regular34 = Font.system(size: 34, weight: .regular)
    static let Regular32 = Font.system(size: 32, weight: .regular)
    static let Regular28 = Font.system(size: 28, weight: .regular)
    static let Regular24 = Font.system(size: 24, weight: .regular)
    static let Regular20 = Font.system(size: 20, weight: .regular)
    static let Regular18 = Font.system(size: 18, weight: .regular)
    static let Regular16 = Font.system(size: 16, weight: .regular)
    static let Regular14 = Font.system(size: 14, weight: .regular)
    static let Regular12 = Font.system(size: 12, weight: .regular)
    static let Regular10 = Font.system(size: 10, weight: .regular)
}
