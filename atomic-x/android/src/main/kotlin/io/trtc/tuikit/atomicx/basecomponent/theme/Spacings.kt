package io.trtc.tuikit.atomicx.basecomponent.theme

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

val DefaultSpacingScheme = SpacingScheme()

data class SpacingScheme(
    val iconTextSpacing: Dp = Spacings.Spacing4,
    val smallSpacing: Dp = Spacings.Spacing8,
    val iconIconSpacing: Dp = Spacings.Spacing12,
    val bubbleSpacing: Dp = Spacings.Spacing16,
    val contentSpacing: Dp = Spacings.Spacing20,
    val normalSpacing: Dp = Spacings.Spacing24,
    val titleSpacing: Dp = Spacings.Spacing32,
    val cardSpacing: Dp = Spacings.Spacing40,
    val largeSpacing: Dp = Spacings.Spacing56,
    val maxSpacing: Dp = Spacings.Spacing72,
)

data object Spacings {
    val Spacing4 = 4.dp
    val Spacing8 = 8.dp
    val Spacing12 = 12.dp
    val Spacing16 = 16.dp
    val Spacing20 = 20.dp
    val Spacing24 = 24.dp
    val Spacing32 = 32.dp
    val Spacing40 = 40.dp
    val Spacing56 = 56.dp
    val Spacing72 = 72.dp
}