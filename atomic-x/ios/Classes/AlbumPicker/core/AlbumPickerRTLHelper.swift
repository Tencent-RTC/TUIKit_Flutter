import SwiftUI

public class AlbumPickerRTLHelper {
    
    public static var isRTL: Bool {
        let currentLanguage = LanguageHelper.getCurrentLanguage()
        return currentLanguage.hasPrefix("ar") || currentLanguage.hasPrefix("he") || currentLanguage.hasPrefix("fa")
    }
    
    public static var layoutDirection: LayoutDirection {
        return isRTL ? .rightToLeft : .leftToRight
    }
}

public struct RTLModifier: ViewModifier {
    let isRTL: Bool
    
    public init(isRTL: Bool = AlbumPickerRTLHelper.isRTL) {
        self.isRTL = isRTL
    }
    
    public func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
    }
}

public struct RTLHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
        .environment(\.layoutDirection, AlbumPickerRTLHelper.layoutDirection)
    }
}

public struct RTLVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: Content
    
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .environment(\.layoutDirection, AlbumPickerRTLHelper.layoutDirection)
    }
}

public extension View {
    func rtlLayout() -> some View {
        self.modifier(RTLModifier())
    }
    
    func rtlFlipped() -> some View {
        self.scaleEffect(x: AlbumPickerRTLHelper.isRTL ? -1 : 1, y: 1)
    }
}
