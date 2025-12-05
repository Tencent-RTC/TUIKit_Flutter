package io.trtc.tuikit.atomicx.basecomponent.utils

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.view.Window
import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.window.DialogWindowProvider
import androidx.core.view.WindowCompat
import io.trtc.tuikit.atomicx.basecomponent.theme.LocalTheme
import io.trtc.tuikit.atomicx.basecomponent.theme.ThemeMode

@Composable
fun SetActivitySystemBarAppearance() {
    val window = LocalActivity.current?.window
    SetWindowSystemBarAppearance(window)
}

@Composable
fun SetDialogSystemBarAppearance() {
    val window = (LocalView.current.parent as? DialogWindowProvider)?.window
    SetWindowSystemBarAppearance(window)
}

@Composable
fun SetWindowSystemBarAppearance(window: Window?) {
    val theme = LocalTheme.current
    val colorScheme = theme.currentMode
    val isDarkMode = when (colorScheme) {
        ThemeMode.DARK -> true
        ThemeMode.LIGHT -> false
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
    }
    window?.let {
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = !isDarkMode
        windowInsetsController.isAppearanceLightNavigationBars = !isDarkMode
    }
}

tailrec fun Context.getActivityWindow(): Window? =
    when (this) {
        is Activity -> window
        is ContextWrapper -> baseContext.getActivityWindow()
        else -> null
    }