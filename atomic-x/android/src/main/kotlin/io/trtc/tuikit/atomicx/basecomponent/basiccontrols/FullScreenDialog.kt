package io.trtc.tuikit.atomicx.basecomponent.basiccontrols

import android.view.WindowManager
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.basecomponent.utils.SetDialogSystemBarAppearance

@Composable
fun FullScreenDialog(
    onDismissRequest: () -> Unit,
    properties: DialogProperties = DialogProperties(
        dismissOnBackPress = true,
        dismissOnClickOutside = true,
        usePlatformDefaultWidth = false,
        decorFitsSystemWindows = false
    ),
    content: @Composable () -> Unit
) {
    Dialog(
        onDismissRequest = onDismissRequest,
        properties = properties
    ) {
        val window = (LocalView.current.parent as? DialogWindowProvider)?.window
        window?.setWindowAnimations(R.style.BaseComponent_FullScreenDialog_Animation)

        val dimAmount by animateFloatAsState(
            targetValue = 0.32f,
            animationSpec = tween(
                durationMillis = 220,
                easing = FastOutSlowInEasing
            ),
            label = "dialog_window_dim"
        )
        SideEffect {
            window?.takeIf { it.attributes.dimAmount != dimAmount }?.let { w ->
                w.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                w.attributes = w.attributes.apply {
                    this@apply.dimAmount = dimAmount
                }
            }
        }

        SetDialogSystemBarAppearance()
        content()
    }
}
