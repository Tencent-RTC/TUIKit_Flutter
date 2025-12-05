package io.trtc.tuikit.atomicx.basecomponent.theme

import androidx.compose.ui.graphics.Color

data class ColorScheme(
    // text & icon
    val textColorPrimary: Color = Colors.Black2,
    val textColorSecondary: Color = Colors.Black4,
    val textColorTertiary: Color = Colors.Black5,
    val textColorDisable: Color = Colors.Black6,
    val textColorButton: Color = Colors.White1,
    val textColorButtonDisabled: Color = Colors.White1,
    val textColorLink: Color = Colors.ThemeLight6,
    val textColorLinkHover: Color = Colors.ThemeLight5,
    val textColorLinkActive: Color = Colors.ThemeLight7,
    val textColorLinkDisabled: Color = Colors.ThemeLight2,
    val textColorAntiPrimary: Color = Colors.Black2,
    val textColorAntiSecondary: Color = Colors.Black4,
    val textColorWarning: Color = Colors.OrangeLight6,
    val textColorSuccess: Color = Colors.GreenLight6,
    val textColorError: Color = Colors.RedLight6,
    // background
    val bgColorTopBar: Color = Colors.GrayLight1,
    val bgColorOperate: Color = Colors.White1,
    val bgColorDialog: Color = Colors.White1,
    val bgColorDialogModule: Color = Colors.GrayLight2,
    val bgColorEntryCard: Color = Colors.GrayLight2,
    val bgColorFunction: Color = Colors.GrayLight2,
    val bgColorBottomBar: Color = Colors.White1,
    val bgColorInput: Color = Colors.GrayLight2,
    val bgColorBubbleReciprocal: Color = Colors.GrayLight2,
    val bgColorBubbleOwn: Color = Colors.ThemeLight2,
    val bgColorDefault: Color = Colors.GrayLight2,
    val bgColorTagMask: Color = Colors.White4,
    val bgColorElementMask: Color = Colors.Black6,
    val bgColorMask: Color = Colors.Black4,
    val bgColorMaskDisappeared: Color = Colors.White7,
    val bgColorMaskBegin: Color = Colors.White1,
    val bgColorAvatar: Color = Colors.ThemeLight2,
    // border
    val strokeColorPrimary: Color = Colors.GrayLight3,
    val strokeColorSecondary: Color = Colors.GrayLight2,
    val strokeColorModule: Color = Colors.GrayLight3,
    // shadow
    val shadowColor: Color = Colors.Black8,
    // status
    val listColorDefault: Color = Colors.White1,
    val listColorHover: Color = Colors.GrayLight1,
    val listColorFocused: Color = Colors.ThemeLight1,
    // button
    val buttonColorPrimaryDefault: Color = Colors.ThemeLight6,
    val buttonColorPrimaryHover: Color = Colors.ThemeLight5,
    val buttonColorPrimaryActive: Color = Colors.ThemeLight7,
    val buttonColorPrimaryDisabled: Color = Colors.ThemeLight2,
    val buttonColorSecondaryDefault: Color = Colors.GrayLight2,
    val buttonColorSecondaryHover: Color = Colors.GrayLight1,
    val buttonColorSecondaryActive: Color = Colors.GrayLight3,
    val buttonColorSecondaryDisabled: Color = Colors.GrayLight1,
    val buttonColorAccept: Color = Colors.GreenLight6,
    val buttonColorHangupDefault: Color = Colors.RedLight6,
    val buttonColorHangupDisabled: Color = Colors.RedLight2,
    val buttonColorHangupHover: Color = Colors.RedLight5,
    val buttonColorHangupActive: Color = Colors.RedLight7,
    val buttonColorOn: Color = Colors.White1,
    val buttonColorOff: Color = Colors.Black5,
    // dropdown
    val dropdownColorDefault: Color = Colors.White1,
    val dropdownColorHover: Color = Colors.GrayLight1,
    val dropdownColorActive: Color = Colors.ThemeLight1,
    // scrollbar
    val scrollbarColorDefault: Color = Colors.Black7,
    val scrollbarColorHover: Color = Colors.Black6,
    // floating
    val floatingColorDefault: Color = Colors.White1,
    val floatingColorOperate: Color = Colors.GrayLight2,
    // checkbox
    val checkboxColorSelected: Color = Colors.ThemeLight6,
    // toast
    val toastColorWarning: Color = Colors.OrangeLight1,
    val toastColorSuccess: Color = Colors.GreenLight1,
    val toastColorError: Color = Colors.RedLight1,
    val toastColorDefault: Color = Colors.ThemeLight1,
    // tag
    val tagColorLevel1: Color = Colors.AccentTurquoiseLight,
    val tagColorLevel2: Color = Colors.ThemeLight5,
    val tagColorLevel3: Color = Colors.AccentPurpleLight,
    val tagColorLevel4: Color = Colors.AccentMagentaLight,
    // switch
    val switchColorOff: Color = Colors.GrayLight4,
    val switchColorOn: Color = Colors.ThemeLight6,
    val switchColorButton: Color = Colors.White1,
    // slider
    val sliderColorFilled: Color = Colors.ThemeLight6,
    val sliderColorEmpty: Color = Colors.GrayLight3,
    val sliderColorButton: Color = Colors.White1,
    // tab
    val tabColorSelected: Color = Colors.ThemeLight2,
    val tabColorUnselected: Color = Colors.GrayLight2,
    val tabColorOption: Color = Colors.GrayLight3,
)

val LightColorScheme = ColorScheme()

val DarkColorScheme = ColorScheme(
    // text & icon
    textColorPrimary = Colors.White2,
    textColorSecondary = Colors.White4,
    textColorTertiary = Colors.White6,
    textColorDisable = Colors.White7,
    textColorButton = Colors.White1,
    textColorButtonDisabled = Colors.White5,
    textColorLink = Colors.ThemeDark6,
    textColorLinkHover = Colors.ThemeDark5,
    textColorLinkActive = Colors.ThemeDark7,
    textColorLinkDisabled = Colors.ThemeDark2,
    textColorAntiPrimary = Colors.Black2,
    textColorAntiSecondary = Colors.Black4,
    textColorWarning = Colors.OrangeDark6,
    textColorSuccess = Colors.GreenDark6,
    textColorError = Colors.RedDark6,
    // background
    bgColorTopBar = Colors.GrayDark1,
    bgColorOperate = Colors.GrayDark2,
    bgColorDialog = Colors.GrayDark2,
    bgColorDialogModule = Colors.GrayDark3,
    bgColorEntryCard = Colors.GrayDark3,
    bgColorFunction = Colors.GrayDark4,
    bgColorBottomBar = Colors.GrayDark3,
    bgColorInput = Colors.GrayDark3,
    bgColorBubbleReciprocal = Colors.GrayDark3,
    bgColorBubbleOwn = Colors.ThemeDark7,
    bgColorDefault = Colors.GrayDark1,
    bgColorTagMask = Colors.Black4,
    bgColorElementMask = Colors.Black6,
    bgColorMask = Colors.Black4,
    bgColorMaskDisappeared = Colors.Black8,
    bgColorMaskBegin = Colors.Black2,
    bgColorAvatar = Colors.ThemeDark2,
    // border
    strokeColorPrimary = Colors.GrayDark4,
    strokeColorSecondary = Colors.GrayDark3,
    strokeColorModule = Colors.GrayDark5,
    // shadow
    shadowColor = Colors.Black8,
    // status
    listColorDefault = Colors.GrayDark2,
    listColorHover = Colors.GrayDark3,
    listColorFocused = Colors.ThemeDark2,
    // button
    buttonColorPrimaryDefault = Colors.ThemeDark6,
    buttonColorPrimaryHover = Colors.ThemeDark5,
    buttonColorPrimaryActive = Colors.ThemeDark7,
    buttonColorPrimaryDisabled = Colors.ThemeDark2,
    buttonColorSecondaryDefault = Colors.GrayDark4,
    buttonColorSecondaryHover = Colors.GrayDark3,
    buttonColorSecondaryActive = Colors.GrayDark5,
    buttonColorSecondaryDisabled = Colors.GrayDark3,
    buttonColorAccept = Colors.GreenDark6,
    buttonColorHangupDefault = Colors.RedDark6,
    buttonColorHangupDisabled = Colors.RedDark2,
    buttonColorHangupHover = Colors.RedDark5,
    buttonColorHangupActive = Colors.RedDark7,
    buttonColorOn = Colors.White1,
    buttonColorOff = Colors.Black5,
    // dropdown
    dropdownColorDefault = Colors.GrayDark3,
    dropdownColorHover = Colors.GrayDark4,
    dropdownColorActive = Colors.GrayDark2,
    // scrollbar
    scrollbarColorDefault = Colors.White7,
    scrollbarColorHover = Colors.White6,
    // floating
    floatingColorDefault = Colors.GrayDark3,
    floatingColorOperate = Colors.GrayDark4,
    // checkbox
    checkboxColorSelected = Colors.ThemeDark5,
    // toast
    toastColorWarning = Colors.OrangeDark2,
    toastColorSuccess = Colors.GreenDark2,
    toastColorError = Colors.RedDark2,
    toastColorDefault = Colors.ThemeDark2,
    // tag
    tagColorLevel1 = Colors.AccentTurquoiseDark,
    tagColorLevel2 = Colors.ThemeDark5,
    tagColorLevel3 = Colors.AccentPurpleDark,
    tagColorLevel4 = Colors.AccentMagentaDark,
    // switch
    switchColorOff = Colors.GrayDark4,
    switchColorOn = Colors.ThemeDark5,
    switchColorButton = Colors.White1,
    // slider
    sliderColorFilled = Colors.ThemeDark5,
    sliderColorEmpty = Colors.GrayDark5,
    sliderColorButton = Colors.White1,
    // tab
    tabColorSelected = Colors.GrayDark5,
    tabColorUnselected = Colors.GrayDark4,
    tabColorOption = Colors.GrayDark4,
)

