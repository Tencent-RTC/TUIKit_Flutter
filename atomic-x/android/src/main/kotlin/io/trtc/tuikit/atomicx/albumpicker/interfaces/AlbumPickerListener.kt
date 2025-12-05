package io.trtc.tuikit.atomicx.albumpicker.interfaces;

import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerModel

interface AlbumPickerListener {
    fun onFinishedSelect(count: Int)

    fun onProgress(model: AlbumPickerModel, index: Int, progress: Double)
}
