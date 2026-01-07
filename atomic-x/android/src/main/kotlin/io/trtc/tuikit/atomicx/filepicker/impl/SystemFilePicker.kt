package io.trtc.tuikit.atomicx.filepicker.impl

import android.content.Intent
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider
import io.trtc.tuikit.atomicx.filepicker.FilePickerConfig
import io.trtc.tuikit.atomicx.filepicker.FilePickerListener

class SystemFilePicker {

    companion object {
        internal var filePickerListener: FilePickerListener? = null
        internal var filePickerConfig: FilePickerConfig? = null
    }

    fun pickFiles(config: FilePickerConfig, listener: FilePickerListener) {
        filePickerListener = listener
        filePickerConfig = config

        val context = ContextProvider.appContext
        val intent = Intent(context, FilePickerBridgeActivity::class.java).apply {
            if (context !is android.app.Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }
}
