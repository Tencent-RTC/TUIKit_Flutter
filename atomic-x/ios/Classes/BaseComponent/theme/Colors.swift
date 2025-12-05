import SwiftUI

public let LightSemanticScheme = SemanticColorScheme(
    // text & icon
    textColorPrimary: Colors.Black2,
    textColorSecondary: Colors.Black4,
    textColorTertiary: Colors.Black5,
    textColorDisable: Colors.Black6,
    textColorButton: Colors.White1,
    textColorButtonDisabled: Colors.White1,
    textColorLink: Colors.ThemeLight6,
    textColorLinkHover: Colors.ThemeLight5,
    textColorLinkActive: Colors.ThemeLight7,
    textColorLinkDisabled: Colors.ThemeLight2,
    textColorAntiPrimary: Colors.Black2,
    textColorAntiSecondary: Colors.Black4,
    textColorWarning: Colors.OrangeLight6,
    textColorSuccess: Colors.GreenLight6,
    textColorError: Colors.RedLight6,
    // background
    bgColorTopBar: Colors.GrayLight1,
    bgColorOperate: Colors.White1,
    bgColorDialog: Colors.White1,
    bgColorDialogModule: Colors.GrayLight2,
    bgColorEntryCard: Colors.GrayLight2,
    bgColorFunction: Colors.GrayLight2,
    bgColorBottomBar: Colors.White1,
    bgColorInput: Colors.GrayLight2,
    bgColorBubbleReciprocal: Colors.GrayLight2,
    bgColorBubbleOwn: Colors.ThemeLight2,
    bgColorDefault: Colors.GrayLight2,
    bgColorTagMask: Colors.White4,
    bgColorElementMask: Colors.Black6,
    bgColorMask: Colors.Black4,
    bgColorMaskDisappeared: Colors.White7,
    bgColorMaskBegin: Colors.White1,
    bgColorAvatar: Colors.ThemeLight2,
    // border
    strokeColorPrimary: Colors.GrayLight3,
    strokeColorSecondary: Colors.GrayLight2,
    strokeColorModule: Colors.GrayLight3,
    // shadow
    shadowColor: Colors.Black8,
    // status
    listColorDefault: Colors.White1,
    listColorHover: Colors.GrayLight1,
    listColorFocused: Colors.ThemeLight1,
    // button
    buttonColorPrimaryDefault: Colors.ThemeLight6,
    buttonColorPrimaryHover: Colors.ThemeLight5,
    buttonColorPrimaryActive: Colors.ThemeLight7,
    buttonColorPrimaryDisabled: Colors.ThemeLight2,
    buttonColorSecondaryDefault: Colors.GrayLight2,
    buttonColorSecondaryHover: Colors.GrayLight1,
    buttonColorSecondaryActive: Colors.GrayLight3,
    buttonColorSecondaryDisabled: Colors.GrayLight1,
    buttonColorAccept: Colors.GreenLight6,
    buttonColorHangupDefault: Colors.RedLight6,
    buttonColorHangupDisabled: Colors.RedLight2,
    buttonColorHangupHover: Colors.RedLight5,
    buttonColorHangupActive: Colors.RedLight7,
    buttonColorOn: Colors.White1,
    buttonColorOff: Colors.Black5,
    // dropdown
    dropdownColorDefault: Colors.White1,
    dropdownColorHover: Colors.GrayLight1,
    dropdownColorActive: Colors.ThemeLight1,
    // scrollbar
    scrollbarColorDefault: Colors.Black7,
    scrollbarColorHover: Colors.Black6,
    // floating
    floatingColorDefault: Colors.White1,
    floatingColorOperate: Colors.GrayLight2,
    // checkbox
    checkboxColorSelected: Colors.ThemeLight6,
    // toast
    toastColorWarning: Colors.OrangeLight1,
    toastColorSuccess: Colors.GreenLight1,
    toastColorError: Colors.RedLight1,
    toastColorDefault: Colors.ThemeLight1,
    // tag
    tagColorLevel1: Colors.AccentTurquoiseLight,
    tagColorLevel2: Colors.ThemeLight5,
    tagColorLevel3: Colors.AccentPurpleLight,
    tagColorLevel4: Colors.AccentMagentaLight,
    // switch
    switchColorOff: Colors.GrayLight4,
    switchColorOn: Colors.ThemeLight6,
    switchColorButton: Colors.White1,
    // slider
    sliderColorFilled: Colors.ThemeLight6,
    sliderColorEmpty: Colors.GrayLight3,
    sliderColorButton: Colors.White1,
    // tab
    tabColorSelected: Colors.ThemeLight2,
    tabColorUnselected: Colors.GrayLight2,
    tabColorOption: Colors.GrayLight3,
    // clear
    clearColor: Colors.Transparent
)
public let DarkSemanticScheme = SemanticColorScheme(
    // text & icon
    textColorPrimary: Colors.White2,
    textColorSecondary: Colors.White4,
    textColorTertiary: Colors.White6,
    textColorDisable: Colors.White7,
    textColorButton: Colors.White1,
    textColorButtonDisabled: Colors.White5,
    textColorLink: Colors.ThemeDark6,
    textColorLinkHover: Colors.ThemeDark5,
    textColorLinkActive: Colors.ThemeDark7,
    textColorLinkDisabled: Colors.ThemeDark2,
    textColorAntiPrimary: Colors.Black2,
    textColorAntiSecondary: Colors.Black4,
    textColorWarning: Colors.OrangeDark6,
    textColorSuccess: Colors.GreenDark6,
    textColorError: Colors.RedDark6,
    // background
    bgColorTopBar: Colors.GrayDark1,
    bgColorOperate: Colors.GrayDark2,
    bgColorDialog: Colors.GrayDark2,
    bgColorDialogModule: Colors.GrayDark3,
    bgColorEntryCard: Colors.GrayDark3,
    bgColorFunction: Colors.GrayDark4,
    bgColorBottomBar: Colors.GrayDark3,
    bgColorInput: Colors.GrayDark3,
    bgColorBubbleReciprocal: Colors.GrayDark3,
    bgColorBubbleOwn: Colors.ThemeDark7,
    bgColorDefault: Colors.GrayDark1,
    bgColorTagMask: Colors.Black4,
    bgColorElementMask: Colors.Black6,
    bgColorMask: Colors.Black4,
    bgColorMaskDisappeared: Colors.Black8,
    bgColorMaskBegin: Colors.Black2,
    bgColorAvatar: Colors.ThemeDark2,
    // border
    strokeColorPrimary: Colors.GrayDark4,
    strokeColorSecondary: Colors.GrayDark3,
    strokeColorModule: Colors.GrayDark5,
    // shadow
    shadowColor: Colors.Black8,
    // status
    listColorDefault: Colors.GrayDark2,
    listColorHover: Colors.GrayDark3,
    listColorFocused: Colors.ThemeDark2,
    // button
    buttonColorPrimaryDefault: Colors.ThemeDark6,
    buttonColorPrimaryHover: Colors.ThemeDark5,
    buttonColorPrimaryActive: Colors.ThemeDark7,
    buttonColorPrimaryDisabled: Colors.ThemeDark2,
    buttonColorSecondaryDefault: Colors.GrayDark4,
    buttonColorSecondaryHover: Colors.GrayDark3,
    buttonColorSecondaryActive: Colors.GrayDark5,
    buttonColorSecondaryDisabled: Colors.GrayDark3,
    buttonColorAccept: Colors.GreenDark6,
    buttonColorHangupDefault: Colors.RedDark6,
    buttonColorHangupDisabled: Colors.RedDark2,
    buttonColorHangupHover: Colors.RedDark5,
    buttonColorHangupActive: Colors.RedDark7,
    buttonColorOn: Colors.White1,
    buttonColorOff: Colors.Black5,
    // dropdown
    dropdownColorDefault: Colors.GrayDark3,
    dropdownColorHover: Colors.GrayDark4,
    dropdownColorActive: Colors.GrayDark2,
    // scrollbar
    scrollbarColorDefault: Colors.White7,
    scrollbarColorHover: Colors.White6,
    // floating
    floatingColorDefault: Colors.GrayDark3,
    floatingColorOperate: Colors.GrayDark4,
    // checkbox
    checkboxColorSelected: Colors.ThemeDark5,
    // toast
    toastColorWarning: Colors.OrangeDark2,
    toastColorSuccess: Colors.GreenDark2,
    toastColorError: Colors.RedDark2,
    toastColorDefault: Colors.ThemeDark2,
    // tag
    tagColorLevel1: Colors.AccentTurquoiseDark,
    tagColorLevel2: Colors.ThemeDark5,
    tagColorLevel3: Colors.AccentPurpleDark,
    tagColorLevel4: Colors.AccentMagentaDark,
    // switch
    switchColorOff: Colors.GrayDark4,
    switchColorOn: Colors.ThemeDark5,
    switchColorButton: Colors.White1,
    // slider
    sliderColorFilled: Colors.ThemeDark5,
    sliderColorEmpty: Colors.GrayDark5,
    sliderColorButton: Colors.White1,
    // tab
    tabColorSelected: Colors.GrayDark5,
    tabColorUnselected: Colors.GrayDark4,
    tabColorOption: Colors.GrayDark4,
    // clear
    clearColor: Colors.Transparent
)
public struct SemanticColorScheme {
    // text & icon
    public let textColorPrimary: Color
    public let textColorSecondary: Color
    public let textColorTertiary: Color
    public let textColorDisable: Color
    public let textColorButton: Color
    public let textColorButtonDisabled: Color
    public let textColorLink: Color
    public let textColorLinkHover: Color
    public let textColorLinkActive: Color
    public let textColorLinkDisabled: Color
    public let textColorAntiPrimary: Color
    public let textColorAntiSecondary: Color
    public let textColorWarning: Color
    public let textColorSuccess: Color
    public let textColorError: Color
    // background
    public let bgColorTopBar: Color
    public let bgColorOperate: Color
    public let bgColorDialog: Color
    public let bgColorDialogModule: Color
    public let bgColorEntryCard: Color
    public let bgColorFunction: Color
    public let bgColorBottomBar: Color
    public let bgColorInput: Color
    public let bgColorBubbleReciprocal: Color
    public let bgColorBubbleOwn: Color
    public let bgColorDefault: Color
    public let bgColorTagMask: Color
    public let bgColorElementMask: Color
    public let bgColorMask: Color
    public let bgColorMaskDisappeared: Color
    public let bgColorMaskBegin: Color
    public let bgColorAvatar: Color
    // border
    public let strokeColorPrimary: Color
    public let strokeColorSecondary: Color
    public let strokeColorModule: Color
    // shadow
    public let shadowColor: Color
    // status
    public let listColorDefault: Color
    public let listColorHover: Color
    public let listColorFocused: Color
    // button
    public let buttonColorPrimaryDefault: Color
    public let buttonColorPrimaryHover: Color
    public let buttonColorPrimaryActive: Color
    public let buttonColorPrimaryDisabled: Color
    public let buttonColorSecondaryDefault: Color
    public let buttonColorSecondaryHover: Color
    public let buttonColorSecondaryActive: Color
    public let buttonColorSecondaryDisabled: Color
    public let buttonColorAccept: Color
    public let buttonColorHangupDefault: Color
    public let buttonColorHangupDisabled: Color
    public let buttonColorHangupHover: Color
    public let buttonColorHangupActive: Color
    public let buttonColorOn: Color
    public let buttonColorOff: Color
    // dropdown
    public let dropdownColorDefault: Color
    public let dropdownColorHover: Color
    public let dropdownColorActive: Color
    // scrollbar
    public let scrollbarColorDefault: Color
    public let scrollbarColorHover: Color
    // floating
    public let floatingColorDefault: Color
    public let floatingColorOperate: Color
    // checkbox
    public let checkboxColorSelected: Color
    // toast
    public let toastColorWarning: Color
    public let toastColorSuccess: Color
    public let toastColorError: Color
    public let toastColorDefault: Color
    // tag
    public let tagColorLevel1: Color
    public let tagColorLevel2: Color
    public let tagColorLevel3: Color
    public let tagColorLevel4: Color
    // switch
    public let switchColorOff: Color
    public let switchColorOn: Color
    public let switchColorButton: Color
    // slider
    public let sliderColorFilled: Color
    public let sliderColorEmpty: Color
    public let sliderColorButton: Color
    // tab
    public let tabColorSelected: Color
    public let tabColorUnselected: Color
    public let tabColorOption: Color
    // clear
    public let clearColor: Color
}

// MARK: - Colors

public enum Colors {
    // Black
    public static let Black1 = Color(hexValue: 0xFF000000)
    public static let Black2 = Color(hexValue: 0xE6000000)
    public static let Black3 = Color(hexValue: 0xB8000000)
    public static let Black4 = Color(hexValue: 0x8C000000)
    public static let Black5 = Color(hexValue: 0x66000000)
    public static let Black6 = Color(hexValue: 0x40000000)
    public static let Black7 = Color(hexValue: 0x1F000000)
    public static let Black8 = Color(hexValue: 0x0F000000)
    // White
    public static let White1 = Color(hexValue: 0xFFFFFFFF)
    public static let White2 = Color(hexValue: 0xEDFFFFFF)
    public static let White3 = Color(hexValue: 0xBFFFFFFF)
    public static let White4 = Color(hexValue: 0x8CFFFFFF)
    public static let White5 = Color(hexValue: 0x6BFFFFFF)
    public static let White6 = Color(hexValue: 0x4DFFFFFF)
    public static let White7 = Color(hexValue: 0x24FFFFFF)
    // Gray Light
    public static let GrayLight1 = Color(hexValue: 0xFFF9FAFC)
    public static let GrayLight2 = Color(hexValue: 0xFFF0F2F7)
    public static let GrayLight3 = Color(hexValue: 0xFFE6E9F0)
    public static let GrayLight4 = Color(hexValue: 0xFFD1D4DE)
    public static let GrayLight5 = Color(hexValue: 0xFFC0C3CC)
    public static let GrayLight6 = Color(hexValue: 0xFFB3B6BE)
    public static let GrayLight7 = Color(hexValue: 0xFFA5A9B0)
    // Gray Dark
    public static let GrayDark1 = Color(hexValue: 0xFF131417)
    public static let GrayDark2 = Color(hexValue: 0xFF1F2024)
    public static let GrayDark3 = Color(hexValue: 0xFF2B2C30)
    public static let GrayDark4 = Color(hexValue: 0xFF3A3C42)
    public static let GrayDark5 = Color(hexValue: 0xFF48494F)
    public static let GrayDark6 = Color(hexValue: 0xFF54565C)
    public static let GrayDark7 = Color(hexValue: 0xFF646A70)
    // Theme Light
    public static let ThemeLight1 = Color(hexValue: 0xFFEBF3FF)
    public static let ThemeLight2 = Color(hexValue: 0xFFCCE2FF)
    public static let ThemeLight3 = Color(hexValue: 0xFFADCFFF)
    public static let ThemeLight4 = Color(hexValue: 0xFF7AAFFF)
    public static let ThemeLight5 = Color(hexValue: 0xFF4588F5)
    public static let ThemeLight6 = Color(hexValue: 0xFF1C66E5)
    public static let ThemeLight7 = Color(hexValue: 0xFF0D49BF)
    public static let ThemeLight8 = Color(hexValue: 0xFF033099)
    public static let ThemeLight9 = Color(hexValue: 0xFF001F73)
    public static let ThemeLight10 = Color(hexValue: 0xFF00124D)
    // Theme Dark
    public static let ThemeDark1 = Color(hexValue: 0xFF1C2333)
    public static let ThemeDark2 = Color(hexValue: 0xFF243047)
    public static let ThemeDark3 = Color(hexValue: 0xFF2F4875)
    public static let ThemeDark4 = Color(hexValue: 0xFF305BA6)
    public static let ThemeDark5 = Color(hexValue: 0xFF2B6AD6)
    public static let ThemeDark6 = Color(hexValue: 0xFF4086FF)
    public static let ThemeDark7 = Color(hexValue: 0xFF5C9DFF)
    public static let ThemeDark8 = Color(hexValue: 0xFF78B0FF)
    public static let ThemeDark9 = Color(hexValue: 0xFF9CC7FF)
    public static let ThemeDark10 = Color(hexValue: 0xFFC2DEFF)
    // Green Light for Success
    public static let GreenLight1 = Color(hexValue: 0xFFE1F7EB)
    public static let GreenLight2 = Color(hexValue: 0xFFB6F0D1)
    public static let GreenLight3 = Color(hexValue: 0xFF84E3B5)
    public static let GreenLight4 = Color(hexValue: 0xFF5AD69E)
    public static let GreenLight5 = Color(hexValue: 0xFF3CC98C)
    public static let GreenLight6 = Color(hexValue: 0xFF0ABF77)
    public static let GreenLight7 = Color(hexValue: 0xFF09A768)
    public static let GreenLight8 = Color(hexValue: 0xFF078F59)
    public static let GreenLight9 = Color(hexValue: 0xFF067049)
    public static let GreenLight10 = Color(hexValue: 0xFF044D37)
    // Green Dark for Success
    public static let GreenDark1 = Color(hexValue: 0xFF1A2620)
    public static let GreenDark2 = Color(hexValue: 0xFF22352C)
    public static let GreenDark3 = Color(hexValue: 0xFF2F4F3F)
    public static let GreenDark4 = Color(hexValue: 0xFF377355)
    public static let GreenDark5 = Color(hexValue: 0xFF368F65)
    public static let GreenDark6 = Color(hexValue: 0xFF38A673)
    public static let GreenDark7 = Color(hexValue: 0xFF62B58B)
    public static let GreenDark8 = Color(hexValue: 0xFF8BC7A9)
    public static let GreenDark9 = Color(hexValue: 0xFFA9D4BD)
    public static let GreenDark10 = Color(hexValue: 0xFFC8E5D5)
    // Red Light for Error
    public static let RedLight1 = Color(hexValue: 0xFFFFE7E6)
    public static let RedLight2 = Color(hexValue: 0xFFFCC9C7)
    public static let RedLight3 = Color(hexValue: 0xFFFAAEAC)
    public static let RedLight4 = Color(hexValue: 0xFFF58989)
    public static let RedLight5 = Color(hexValue: 0xFFE86666)
    public static let RedLight6 = Color(hexValue: 0xFFE54545)
    public static let RedLight7 = Color(hexValue: 0xFFC93439)
    public static let RedLight8 = Color(hexValue: 0xFFAD2934)
    public static let RedLight9 = Color(hexValue: 0xFF8F222D)
    public static let RedLight10 = Color(hexValue: 0xFF6B1A27)
    // Red Dark for Error
    public static let RedDark1 = Color(hexValue: 0xFF2B1C1F)
    public static let RedDark2 = Color(hexValue: 0xFF422324)
    public static let RedDark3 = Color(hexValue: 0xFF613234)
    public static let RedDark4 = Color(hexValue: 0xFF8A4242)
    public static let RedDark5 = Color(hexValue: 0xFFC2544E)
    public static let RedDark6 = Color(hexValue: 0xFFE6594C)
    public static let RedDark7 = Color(hexValue: 0xFFE57A6E)
    public static let RedDark8 = Color(hexValue: 0xFFF3A599)
    public static let RedDark9 = Color(hexValue: 0xFFFACBC3)
    public static let RedDark10 = Color(hexValue: 0xFFFAE4DE)
    // Orange Light for Warning
    public static let OrangeLight1 = Color(hexValue: 0xFFFFEEDB)
    public static let OrangeLight2 = Color(hexValue: 0xFFFFD6B2)
    public static let OrangeLight3 = Color(hexValue: 0xFFFFBE85)
    public static let OrangeLight4 = Color(hexValue: 0xFFFFA455)
    public static let OrangeLight5 = Color(hexValue: 0xFFFF8B2B)
    public static let OrangeLight6 = Color(hexValue: 0xFFFF7200)
    public static let OrangeLight7 = Color(hexValue: 0xFFE05D00)
    public static let OrangeLight8 = Color(hexValue: 0xFFBF4900)
    public static let OrangeLight9 = Color(hexValue: 0xFF8F370B)
    public static let OrangeLight10 = Color(hexValue: 0xFF662200)
    // Orange Dark for Warning
    public static let OrangeDark1 = Color(hexValue: 0xFF211A19)
    public static let OrangeDark2 = Color(hexValue: 0xFF35231A)
    public static let OrangeDark3 = Color(hexValue: 0xFF462E1F)
    public static let OrangeDark4 = Color(hexValue: 0xFF653C21)
    public static let OrangeDark5 = Color(hexValue: 0xFF96562A)
    public static let OrangeDark6 = Color(hexValue: 0xFFE37F32)
    public static let OrangeDark7 = Color(hexValue: 0xFFE39552)
    public static let OrangeDark8 = Color(hexValue: 0xFFEEAD72)
    public static let OrangeDark9 = Color(hexValue: 0xFFF7CFA4)
    public static let OrangeDark10 = Color(hexValue: 0xFFF9E9D1)
    // Transparent
    public static let Transparent = Color.clear
    // Accent Light for
    public static let AccentTurquoiseLight = Color(hexValue: 0xFF00ABD6)
    public static let AccentPurpleLight = Color(hexValue: 0xFF8157FF)
    public static let AccentMagentaLight = Color(hexValue: 0xFFF5457F)
    public static let AccentOrangeLight = Color(hexValue: 0xFFFF6A4C)
    // Accent Dark
    public static let AccentTurquoiseDark = Color(hexValue: 0xFF008FB2)
    public static let AccentPurpleDark = Color(hexValue: 0xFF693CF0)
    public static let AccentMagentaDark = Color(hexValue: 0xFFC22F56)
    public static let AccentOrangeDark = Color(hexValue: 0xFFF25B35)
}
