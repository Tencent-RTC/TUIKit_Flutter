import SwiftUI

public let RadiusScheme = SemanticRadiusScheme(
    tipsRadius: Radius.Radius4,
    smallRadius: Radius.Radius8,
    alertRadius: Radius.Radius12,
    largeRadius: Radius.Radius16,
    superLargeRadius: Radius.Radius20,
    roundRadius: Radius.Radius999
)
public struct SemanticRadiusScheme {
    public let tipsRadius: Int
    public let smallRadius: Int
    public let alertRadius: Int
    public let largeRadius: Int
    public let superLargeRadius: Int
    public let roundRadius: Int
}

private enum Radius {
    static let Radius4 = 4
    static let Radius8 = 8
    static let Radius12 = 12
    static let Radius16 = 16
    static let Radius20 = 20
    static let Radius999 = 999
}
