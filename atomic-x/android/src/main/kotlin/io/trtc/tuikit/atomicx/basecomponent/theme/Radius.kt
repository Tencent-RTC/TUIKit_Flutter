package io.trtc.tuikit.atomicx.basecomponent.theme

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

val DefaultRadiusScheme = RadiusScheme()

data class RadiusScheme(
    val tipsRadius: Dp = Radius.Radius4,
    val smallRadius: Dp = Radius.Radius8,
    val alertRadius: Dp = Radius.Radius12,
    val largeRadius: Dp = Radius.Radius16,
    val superLargeRadius: Dp = Radius.Radius20,
    val roundRadius: Dp = Radius.Radius999,
)

data object Radius {
    val Radius4 = 4.dp
    val Radius8 = 8.dp
    val Radius12 = 12.dp
    val Radius16 = 16.dp
    val Radius20 = 20.dp
    val Radius999 = 999.dp
}
