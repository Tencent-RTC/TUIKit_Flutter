package io.trtc.tuikit.atomicx.basecomponent.theme

import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

data class Font(val size: TextUnit, val weight: FontWeight)

val DefaultFontScheme = FontScheme()

data class FontScheme(
    val title1Bold: Font = Fonts.Bold40,
    val title2Bold: Font = Fonts.Bold36,
    val title3Bold: Font = Fonts.Bold34,
    val title4Bold: Font = Fonts.Bold32,
    val body1Bold: Font = Fonts.Bold28,
    val body2Bold: Font = Fonts.Bold24,
    val body3Bold: Font = Fonts.Bold20,
    val body4Bold: Font = Fonts.Bold18,
    val caption1Bold: Font = Fonts.Bold16,
    val caption2Bold: Font = Fonts.Bold14,
    val caption3Bold: Font = Fonts.Bold12,
    val caption4Bold: Font = Fonts.Bold10,

    val title1Medium: Font = Fonts.Medium40,
    val title2Medium: Font = Fonts.Medium36,
    val title3Medium: Font = Fonts.Medium34,
    val title4Medium: Font = Fonts.Medium32,
    val body1Medium: Font = Fonts.Medium28,
    val body2Medium: Font = Fonts.Medium24,
    val body3Medium: Font = Fonts.Medium20,
    val body4Medium: Font = Fonts.Medium18,
    val caption1Medium: Font = Fonts.Medium16,
    val caption2Medium: Font = Fonts.Medium14,
    val caption3Medium: Font = Fonts.Medium12,
    val caption4Medium: Font = Fonts.Medium10,

    val title1Regular: Font = Fonts.Regular40,
    val title2Regular: Font = Fonts.Regular36,
    val title3Regular: Font = Fonts.Regular34,
    val title4Regular: Font = Fonts.Regular32,
    val body1Regular: Font = Fonts.Regular28,
    val body2Regular: Font = Fonts.Regular24,
    val body3Regular: Font = Fonts.Regular20,
    val body4Regular: Font = Fonts.Regular18,
    val caption1Regular: Font = Fonts.Regular16,
    val caption2Regular: Font = Fonts.Regular14,
    val caption3Regular: Font = Fonts.Regular12,
    val caption4Regular: Font = Fonts.Regular10,
)


data object Fonts {
    val Bold40 = Font(size = 40.sp, weight = FontWeight.Bold)
    val Bold36 = Font(size = 36.sp, weight = FontWeight.Bold)
    val Bold34 = Font(size = 34.sp, weight = FontWeight.Bold)
    val Bold32 = Font(size = 32.sp, weight = FontWeight.Bold)
    val Bold28 = Font(size = 28.sp, weight = FontWeight.Bold)
    val Bold24 = Font(size = 24.sp, weight = FontWeight.Bold)
    val Bold20 = Font(size = 20.sp, weight = FontWeight.Bold)
    val Bold18 = Font(size = 18.sp, weight = FontWeight.Bold)
    val Bold16 = Font(size = 16.sp, weight = FontWeight.Bold)
    val Bold14 = Font(size = 14.sp, weight = FontWeight.Bold)
    val Bold12 = Font(size = 12.sp, weight = FontWeight.Bold)
    val Bold10 = Font(size = 10.sp, weight = FontWeight.Bold)

    val Medium40 = Font(size = 40.sp, weight = FontWeight.Medium)
    val Medium36 = Font(size = 36.sp, weight = FontWeight.Medium)
    val Medium34 = Font(size = 34.sp, weight = FontWeight.Medium)
    val Medium32 = Font(size = 32.sp, weight = FontWeight.Medium)
    val Medium28 = Font(size = 28.sp, weight = FontWeight.Medium)
    val Medium24 = Font(size = 24.sp, weight = FontWeight.Medium)
    val Medium20 = Font(size = 20.sp, weight = FontWeight.Medium)
    val Medium18 = Font(size = 18.sp, weight = FontWeight.Medium)
    val Medium16 = Font(size = 16.sp, weight = FontWeight.Medium)
    val Medium14 = Font(size = 14.sp, weight = FontWeight.Medium)
    val Medium12 = Font(size = 12.sp, weight = FontWeight.Medium)
    val Medium10 = Font(size = 10.sp, weight = FontWeight.Medium)

    val Regular40 = Font(size = 40.sp, weight = FontWeight.Normal)
    val Regular36 = Font(size = 36.sp, weight = FontWeight.Normal)
    val Regular34 = Font(size = 34.sp, weight = FontWeight.Normal)
    val Regular32 = Font(size = 32.sp, weight = FontWeight.Normal)
    val Regular28 = Font(size = 28.sp, weight = FontWeight.Normal)
    val Regular24 = Font(size = 24.sp, weight = FontWeight.Normal)
    val Regular20 = Font(size = 20.sp, weight = FontWeight.Normal)
    val Regular18 = Font(size = 18.sp, weight = FontWeight.Normal)
    val Regular16 = Font(size = 16.sp, weight = FontWeight.Normal)
    val Regular14 = Font(size = 14.sp, weight = FontWeight.Normal)
    val Regular12 = Font(size = 12.sp, weight = FontWeight.Normal)
    val Regular10 = Font(size = 10.sp, weight = FontWeight.Normal)
}

