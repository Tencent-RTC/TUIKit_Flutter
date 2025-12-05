import SwiftUI

public enum ThemeMode: String, Equatable, Codable, CaseIterable {
    case system
    case light
    case dark
}

public struct ThemeConfig: Equatable, Codable {
    public let mode: ThemeMode
    public let primaryColor: String?
    public init(mode: ThemeMode, primaryColor: String? = nil) {
        self.mode = mode
        self.primaryColor = primaryColor
    }

    public static func == (lhs: ThemeConfig, rhs: ThemeConfig) -> Bool {
        return lhs.mode == rhs.mode && lhs.primaryColor == rhs.primaryColor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(ThemeMode.self, forKey: .mode)
        primaryColor = try container.decodeIfPresent(String.self, forKey: .primaryColor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(primaryColor, forKey: .primaryColor)
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case primaryColor
    }
}

public class ThemeState: ObservableObject {
    private static let ThemeKey = "BaseComponentThemeKey"
    @Published public var currentTheme: ThemeConfig = .init(mode: .system)
    @Published private var systemInterfaceStyle: UIUserInterfaceStyle = .unspecified
    public static let shared = ThemeState()

    private var cachedColorScheme: SemanticColorScheme?
    private var cachedThemeConfig: ThemeConfig?

    init() {
        loadTheme()
        setupSystemThemeObserver()
    }

    public func setThemeMode(_ mode: ThemeMode) {
        clearCache()
        currentTheme = ThemeConfig(mode: mode, primaryColor: currentTheme.primaryColor)
        saveTheme()
    }

    public func setPrimaryColor(_ hexColor: String) {
        guard hexColor.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil else {
            print("Warning: Invalid hex color format: \(hexColor)")
            return
        }
        clearCache()
        currentTheme = ThemeConfig(mode: currentTheme.mode, primaryColor: hexColor)
        saveTheme()
    }

    public func clearPrimaryColor() {
        clearCache()
        currentTheme = ThemeConfig(mode: currentTheme.mode, primaryColor: nil)
        saveTheme()
    }

    public var currentMode: ThemeMode {
        return currentTheme.mode
    }

    public var currentPrimaryColor: String? {
        return currentTheme.primaryColor
    }

    public var hasCustomPrimaryColor: Bool {
        return currentTheme.primaryColor != nil
    }

    public var colors: SemanticColorScheme {
        if let cached = cachedColorScheme, let cachedConfig = cachedThemeConfig, cachedConfig == currentTheme {
            return cached
        }

        let newColorScheme = calculateColorScheme()
        cachedColorScheme = newColorScheme
        cachedThemeConfig = currentTheme

        return newColorScheme
    }

    public var fonts: SemanticFontScheme {
        return FontScheme
    }

    public var radius: SemanticRadiusScheme {
        return RadiusScheme
    }

    public var spacing: SemanticSpacingScheme {
        return SpacingScheme
    }

    public var isDarkMode: Bool {
        switch currentTheme.mode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            #if os(iOS) || os(tvOS)
            return systemInterfaceStyle == .dark
            #elseif os(macOS)
            return NSAppearance.currentDrawing().name == .darkAqua
            #else
            return false
            #endif
        }
    }

    private func setupSystemThemeObserver() {
        #if os(iOS) || os(tvOS)
        updateSystemInterfaceStyle()

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSystemInterfaceStyle()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("UITraitCollectionDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSystemInterfaceStyle()
        }
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateSystemInterfaceStyle() {
        #if os(iOS) || os(tvOS)
        let newStyle: UIUserInterfaceStyle

        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first
            {
                newStyle = window.traitCollection.userInterfaceStyle
            } else {
                newStyle = UIScreen.main.traitCollection.userInterfaceStyle
            }
        } else {
            newStyle = .unspecified
        }

        if systemInterfaceStyle != newStyle {
            systemInterfaceStyle = newStyle
            clearCache()
        }
        #endif
    }

    private func getSystemScheme() -> SemanticColorScheme {
        return isDarkMode ? DarkSemanticScheme : LightSemanticScheme
    }

    private func calculateColorScheme() -> SemanticColorScheme {
        let effectiveMode: ThemeMode

        switch currentTheme.mode {
        case .system:
            effectiveMode = isDarkMode ? .dark : .light
        case .light, .dark:
            effectiveMode = currentTheme.mode
        }

        if let primaryColor = currentTheme.primaryColor {
            let customColor = Color(hexString: primaryColor)
            return getCustomScheme(isLight: effectiveMode == .light,
                                   baseScheme: effectiveMode == .light ? LightSemanticScheme : DarkSemanticScheme,
                                   primary: customColor)
        }

        switch effectiveMode {
        case .light:
            return LightSemanticScheme
        case .dark:
            return DarkSemanticScheme
        case .system:
            return getSystemScheme()
        }
    }

    private func clearCache() {
        cachedColorScheme = nil
        cachedThemeConfig = nil
    }

    private func saveTheme() {
        if let data = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(data, forKey: Self.ThemeKey)
            UserDefaults.standard.synchronize()
        }
    }

    private func loadTheme() {
        if let data = UserDefaults.standard.data(forKey: Self.ThemeKey),
           let theme = try? JSONDecoder().decode(ThemeConfig.self, from: data)
        {
            currentTheme = theme
            return
        }

        let config = AppBuilderConfig.shared
        let mode: ThemeMode
        switch config.themeMode {
        case .system:
            mode = .system
        case .light:
            mode = .light
        case .dark:
            mode = .dark
        }

        var primaryColor: String? = nil
        if !config.primaryColor.isEmpty {
            if config.primaryColor.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil {
                primaryColor = config.primaryColor
            }
        }

        currentTheme = ThemeConfig(mode: mode, primaryColor: primaryColor)
    }

    private func getCustomScheme(isLight: Bool, baseScheme: SemanticColorScheme, primary: Color) -> SemanticColorScheme {
        let hexColor = primary.hexString()

        let lightPalette = ThemeColorGenerator.generateColorPalette(baseColor: hexColor, theme: "light")
        let darkPalette = ThemeColorGenerator.generateColorPalette(baseColor: hexColor, theme: "dark")

        let themeLight1 = Color(hexString: lightPalette[0])
        let themeLight2 = Color(hexString: lightPalette[1])
        let themeLight5 = Color(hexString: lightPalette[4])
        let themeLight6 = Color(hexString: lightPalette[5])
        let themeLight7 = Color(hexString: lightPalette[6])
        let themeDark2 = Color(hexString: darkPalette[1])
        let themeDark5 = Color(hexString: darkPalette[4])
        let themeDark6 = Color(hexString: darkPalette[5])
        let themeDark7 = Color(hexString: darkPalette[6])

        return SemanticColorScheme(
            textColorPrimary: baseScheme.textColorPrimary,
            textColorSecondary: baseScheme.textColorSecondary,
            textColorTertiary: baseScheme.textColorTertiary,
            textColorDisable: baseScheme.textColorDisable,
            textColorButton: baseScheme.textColorButton,
            textColorButtonDisabled: baseScheme.textColorButtonDisabled,
            textColorLink: isLight ? themeLight6 : themeDark6,
            textColorLinkHover: isLight ? themeLight5 : themeDark5,
            textColorLinkActive: isLight ? themeLight7 : themeDark7,
            textColorLinkDisabled: isLight ? themeLight2 : themeDark2,
            textColorAntiPrimary: baseScheme.textColorAntiPrimary,
            textColorAntiSecondary: baseScheme.textColorAntiSecondary,
            textColorWarning: baseScheme.textColorWarning,
            textColorSuccess: baseScheme.textColorSuccess,
            textColorError: baseScheme.textColorError,
            bgColorTopBar: baseScheme.bgColorTopBar,
            bgColorOperate: baseScheme.bgColorOperate,
            bgColorDialog: baseScheme.bgColorDialog,
            bgColorDialogModule: baseScheme.bgColorDialogModule,
            bgColorEntryCard: baseScheme.bgColorEntryCard,
            bgColorFunction: baseScheme.bgColorFunction,
            bgColorBottomBar: baseScheme.bgColorBottomBar,
            bgColorInput: baseScheme.bgColorInput,
            bgColorBubbleReciprocal: baseScheme.bgColorBubbleReciprocal,
            bgColorBubbleOwn: isLight ? themeLight2 : themeDark7,
            bgColorDefault: baseScheme.bgColorDefault,
            bgColorTagMask: baseScheme.bgColorTagMask,
            bgColorElementMask: baseScheme.bgColorElementMask,
            bgColorMask: baseScheme.bgColorMask,
            bgColorMaskDisappeared: baseScheme.bgColorMaskDisappeared,
            bgColorMaskBegin: baseScheme.bgColorMaskBegin,
            bgColorAvatar: isLight ? themeLight2 : themeDark2,
            strokeColorPrimary: baseScheme.strokeColorPrimary,
            strokeColorSecondary: baseScheme.strokeColorSecondary,
            strokeColorModule: baseScheme.strokeColorModule,
            shadowColor: baseScheme.shadowColor,
            listColorDefault: baseScheme.listColorDefault,
            listColorHover: baseScheme.listColorHover,
            listColorFocused: isLight ? themeLight1 : themeDark2,
            buttonColorPrimaryDefault: isLight ? themeLight6 : themeDark6,
            buttonColorPrimaryHover: isLight ? themeLight5 : themeDark5,
            buttonColorPrimaryActive: isLight ? themeLight7 : themeDark7,
            buttonColorPrimaryDisabled: isLight ? themeLight2 : themeDark2,
            buttonColorSecondaryDefault: baseScheme.buttonColorSecondaryDefault,
            buttonColorSecondaryHover: baseScheme.buttonColorSecondaryHover,
            buttonColorSecondaryActive: baseScheme.buttonColorSecondaryActive,
            buttonColorSecondaryDisabled: baseScheme.buttonColorSecondaryDisabled,
            buttonColorAccept: baseScheme.buttonColorAccept,
            buttonColorHangupDefault: baseScheme.buttonColorHangupDefault,
            buttonColorHangupDisabled: baseScheme.buttonColorHangupDisabled,
            buttonColorHangupHover: baseScheme.buttonColorHangupHover,
            buttonColorHangupActive: baseScheme.buttonColorHangupActive,
            buttonColorOn: baseScheme.buttonColorOn,
            buttonColorOff: baseScheme.buttonColorOff,
            dropdownColorDefault: baseScheme.dropdownColorDefault,
            dropdownColorHover: baseScheme.dropdownColorHover,
            dropdownColorActive: isLight ? themeLight1 : themeDark2,
            scrollbarColorDefault: baseScheme.scrollbarColorDefault,
            scrollbarColorHover: baseScheme.scrollbarColorHover,
            floatingColorDefault: baseScheme.floatingColorDefault,
            floatingColorOperate: baseScheme.floatingColorOperate,
            checkboxColorSelected: isLight ? themeLight6 : themeDark5,
            toastColorWarning: baseScheme.toastColorWarning,
            toastColorSuccess: baseScheme.toastColorSuccess,
            toastColorError: baseScheme.toastColorError,
            toastColorDefault: isLight ? themeLight1 : themeDark2,
            tagColorLevel1: baseScheme.tagColorLevel1,
            tagColorLevel2: baseScheme.tagColorLevel2,
            tagColorLevel3: baseScheme.tagColorLevel3,
            tagColorLevel4: baseScheme.tagColorLevel4,
            switchColorOff: baseScheme.switchColorOff,
            switchColorOn: isLight ? themeLight6 : themeDark5,
            switchColorButton: baseScheme.switchColorButton,
            sliderColorFilled: isLight ? themeLight6 : themeDark5,
            sliderColorEmpty: baseScheme.sliderColorEmpty,
            sliderColorButton: baseScheme.sliderColorButton,
            tabColorSelected: isLight ? themeLight2 : themeDark5,
            tabColorUnselected: baseScheme.tabColorUnselected,
            tabColorOption: baseScheme.tabColorOption,
            clearColor: baseScheme.clearColor
        )
    }
}

class ThemeColorGenerator {
    static func generateColorPalette(baseColor: String, theme: String) -> [String] {
        if isStandardColor(color: baseColor) {
            let palette = getClosestPalette(color: baseColor)
            let targetColors = palette[theme] ?? palette["light"]!
            return targetColors
        }
        return generateDynamicColorVariations(baseColor: baseColor, theme: theme)
    }

    private static let BLUE_PALETTE: [String: [String]] = [
        "light": [
            "#ebf3ff", "#cce2ff", "#adcfff", "#7aafff", "#4588f5",
            "#1c66e5", "#0d49bf", "#033099", "#001f73", "#00124d"
        ],
        "dark": [
            "#1c2333", "#243047", "#2f4875", "#305ba6", "#2b6ad6",
            "#4086ff", "#5c9dff", "#78b0ff", "#9cc7ff", "#c2deff"
        ]
    ]
    private static let GREEN_PALETTE: [String: [String]] = [
        "light": [
            "#dcfae9", "#b6f0d1", "#84e3b5", "#5ad69e", "#3cc98c",
            "#0abf77", "#09a768", "#078f59", "#067049", "#044d37"
        ],
        "dark": [
            "#1a2620", "#22352c", "#2f4f3f", "#377355", "#368f65",
            "#38a673", "#62b58b", "#8bc7a9", "#a9d4bd", "#c8e5d5"
        ]
    ]
    private static let RED_PALETTE: [String: [String]] = [
        "light": [
            "#ffe7e6", "#fcc9c7", "#faaeac", "#f58989", "#e86666",
            "#e54545", "#c93439", "#ad2934", "#8f222d", "#6b1a27"
        ],
        "dark": [
            "#2b1c1f", "#422324", "#613234", "#8a4242", "#c2544e",
            "#e6594c", "#e57a6e", "#f3a599", "#facbc3", "#fae4de"
        ]
    ]
    private static let ORANGE_PALETTE: [String: [String]] = [
        "light": [
            "#ffeedb", "#ffd6b2", "#ffbe85", "#ffa455", "#ff8b2b",
            "#ff7200", "#e05d00", "#bf4900", "#8f370b", "#662200"
        ],
        "dark": [
            "#211a19", "#35231a", "#462e1f", "#653c21", "#96562a",
            "#e37f32", "#e39552", "#eead72", "#f7cfa4", "#f9e9d1"
        ]
    ]
    private static let HSL_ADJUSTMENTS: [String: [Int: (s: Double, l: Double)]] = [
        "light": [
            1: (s: -40, l: 45),
            2: (s: -30, l: 35),
            3: (s: -20, l: 25),
            4: (s: -10, l: 15),
            5: (s: -5, l: 5),
            6: (s: 0, l: 0),
            7: (s: 5, l: -10),
            8: (s: 10, l: -20),
            9: (s: 15, l: -30),
            10: (s: 20, l: -40)
        ],
        "dark": [
            1: (s: -60, l: -35),
            2: (s: -50, l: -25),
            3: (s: -40, l: -15),
            4: (s: -30, l: -5),
            5: (s: -20, l: 5),
            6: (s: 0, l: 0),
            7: (s: -10, l: 15),
            8: (s: -20, l: 30),
            9: (s: -30, l: 45),
            10: (s: -40, l: 60)
        ]
    ]
    private static func getClosestPalette(color: String) -> [String: [String]] {
        let hsl = hexToHSL(color)
        let colorDistance = { (c1: (h: Double, s: Double, l: Double), c2: (h: Double, s: Double, l: Double)) -> Double in
            let dh = min(abs(c1.h - c2.h), 360 - abs(c1.h - c2.h))
            let ds = c1.s - c2.s
            let dl = c1.l - c2.l
            return sqrt(dh * dh + ds * ds + dl * dl)
        }
        let palettes = [
            (palette: BLUE_PALETTE, baseColor: BLUE_PALETTE["light"]![5]),
            (palette: GREEN_PALETTE, baseColor: GREEN_PALETTE["light"]![5]),
            (palette: RED_PALETTE, baseColor: RED_PALETTE["light"]![5]),
            (palette: ORANGE_PALETTE, baseColor: ORANGE_PALETTE["light"]![5])
        ]
        let distances = palettes.map { paletteInfo in
            (palette: paletteInfo.palette, distance: colorDistance(hsl, hexToHSL(paletteInfo.baseColor)))
        }
        return distances.sorted { $0.distance < $1.distance }[0].palette
    }

    private static func isStandardColor(color: String) -> Bool {
        let standardColors = [
            BLUE_PALETTE["light"]![5],
            GREEN_PALETTE["light"]![5],
            RED_PALETTE["light"]![5],
            ORANGE_PALETTE["light"]![5]
        ]
        let inputHsl = hexToHSL(color)
        return standardColors.contains { standardColor in
            let standardHsl = hexToHSL(standardColor)
            let dh = min(abs(inputHsl.h - standardHsl.h), 360 - abs(inputHsl.h - standardHsl.h))
            return dh < 15 && abs(inputHsl.s - standardHsl.s) < 15 && abs(inputHsl.l - standardHsl.l) < 15
        }
    }

    private static func adjustColor(color: String, adjustment: (s: Double, l: Double)) -> String {
        let hsl = hexToHSL(color)
        let newS = max(0, min(100, hsl.s + adjustment.s))
        let newL = max(0, min(100, hsl.l + adjustment.l))
        return hslToHex(h: hsl.h, s: newS, l: newL)
    }

    private static func generateDynamicColorVariations(baseColor: String, theme: String) -> [String] {
        var variations: [String] = []
        let adjustments = HSL_ADJUSTMENTS[theme] ?? HSL_ADJUSTMENTS["light"]!
        let baseHsl = hexToHSL(baseColor)
        let saturationFactor = baseHsl.s > 70 ? 0.8 : baseHsl.s < 30 ? 1.2 : 1.0
        let lightnessFactor = baseHsl.l > 70 ? 0.8 : baseHsl.l < 30 ? 1.2 : 1.0
        for i in 1 ... 10 {
            let adjustment = adjustments[i] ?? (s: 0, l: 0)
            let adjustedS = adjustment.s * saturationFactor
            let adjustedL = adjustment.l * lightnessFactor
            variations.append(adjustColor(color: baseColor, adjustment: (s: adjustedS, l: adjustedL)))
        }
        return variations
    }

    private static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        var h: Double = 0
        var s: Double = 0
        let l = (max + min) / 2.0
        if max != min {
            let d = max - min
            s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min)
            switch max {
            case r:
                h = (g - b) / d + (g < b ? 6.0 : 0.0)
            case g:
                h = (b - r) / d + 2.0
            case b:
                h = (r - g) / d + 4.0
            default:
                break
            }
            h /= 6.0
        }
        return (h: h * 360.0, s: s * 100.0, l: l * 100.0)
    }

    private static func hslToHex(h: Double, s: Double, l: Double) -> String {
        let h = h / 360.0
        let s = s / 100.0
        let l = l / 100.0
        let c = (1.0 - abs(2.0 * l - 1.0)) * s
        let x = c * (1.0 - abs((h * 6.0).truncatingRemainder(dividingBy: 2.0) - 1.0))
        let m = l - c / 2.0
        var r: Double = 0, g: Double = 0, b: Double = 0
        switch Int(h * 6.0) {
        case 0:
            r = c; g = x; b = 0
        case 1:
            r = x; g = c; b = 0
        case 2:
            r = 0; g = c; b = x
        case 3:
            r = 0; g = x; b = c
        case 4:
            r = x; g = 0; b = c
        case 5:
            r = c; g = 0; b = x
        default:
            break
        }
        let red = Int((r + m) * 255.0)
        let green = Int((g + m) * 255.0)
        let blue = Int((b + m) * 255.0)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

public extension Color {
    init(hexValue: UInt32) {
        let alpha = Double((hexValue >> 24) & 0xFF) / 255.0
        let red = Double((hexValue >> 16) & 0xFF) / 255.0
        let green = Double((hexValue >> 8) & 0xFF) / 255.0
        let blue = Double(hexValue & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(hexString: String) {
        let hex = hexString.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue)
    }

    func hexString() -> String {
        #if os(iOS) || os(tvOS)
        if #available(iOS 14.0, *) {
            let uiColor = UIColor(self)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let r = Int(red * 255.0)
            let g = Int(green * 255.0)
            let b = Int(blue * 255.0)
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return "#007AFF"
        }
        #else
        return "#007AFF"
        #endif
    }

    func toUIColor() -> UIColor {
        UIColor(self)
    }
}
