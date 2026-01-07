package io.trtc.tuikit.atomicx.filepicker

import android.net.Uri
import io.trtc.tuikit.atomicx.filepicker.impl.SystemFilePicker

interface FilePickerListener {
    fun onPicked(result: List<FilePickerResult>)
    fun onCanceled()
}

data class FilePickerConfig(
    val allowedMimeTypes: List<String> = emptyList(),
    val maxCount: Int = 1,
)

data class FilePickerResult(
    val filePath: String,
    val fileName: String,
    val fileSize: Long,
    val extension: String
)

object FilePicker {
    private val instance = SystemFilePicker()
    
    fun pickFiles(config: FilePickerConfig = FilePickerConfig(), listener: FilePickerListener) {
        instance.pickFiles(config, listener)
    }
}
