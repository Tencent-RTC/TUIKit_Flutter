/*
 * Copyright (c) 2025 Tencent
 * All rights reserved.
 *
 * Author: eddardliu
 */

package io.trtc.tuikit.atomicx.imageuploader

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max

class SystemImageSourceActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_SOURCE = "source"
        const val SOURCE_CAMERA = "camera"
        const val SOURCE_GALLERY = "gallery"
        private const val TAG = "SystemImagePicker"
        private const val MAX_DIMENSION = 4096
    }

    private var cameraPhotoUri: Uri? = null

    private val photoPickerLauncher: ActivityResultLauncher<PickVisualMediaRequest> =
        registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            if (uri != null) handleImageSelected(uri) else finishWithResult(null)
        }

    private val legacyGalleryLauncher: ActivityResultLauncher<Intent> =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == RESULT_OK) {
                result.data?.data?.let { handleImageSelected(it) } ?: finishWithResult(null)
            } else {
                finishWithResult(null)
            }
        }

    private val takePicture: ActivityResultLauncher<Uri> =
        registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
            if (success && cameraPhotoUri != null) handleImageSelected(cameraPhotoUri!!)
            else finishWithResult(null)
        }

    private val requestCameraPermission: ActivityResultLauncher<String> =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) launchCamera() else finishWithResult(null)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val source = intent?.getStringExtra(EXTRA_SOURCE) ?: SOURCE_GALLERY

        when (source) {
            SOURCE_CAMERA -> {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                    == PackageManager.PERMISSION_GRANTED
                ) {
                    launchCamera()
                } else {
                    requestCameraPermission.launch(Manifest.permission.CAMERA)
                }
            }
            else -> launchImagePicker()
        }
    }

    private fun launchCamera() {
        val photoFile = createImageFile()
        cameraPhotoUri = FileProvider.getUriForFile(
            this, "${packageName}.imageuploader.fileprovider", photoFile
        )
        cameraPhotoUri?.let { takePicture.launch(it) } ?: finishWithResult(null)
    }

    private fun generateFileName(extension: String): String {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val random = (0 until Int.MAX_VALUE).random()
        return "IMG_${timeStamp}_${random}.${extension}"
    }

    private fun createImageFile(): File {
        val storageDir = File(externalCacheDir, "Pictures")
        if (!storageDir.exists()) storageDir.mkdirs()
        return File(storageDir, generateFileName("jpg"))
    }

    private fun launchImagePicker() {
        if (ActivityResultContracts.PickVisualMedia.isPhotoPickerAvailable(this)) {
            photoPickerLauncher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
        } else {
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            legacyGalleryLauncher.launch(intent)
        }
    }

    private fun handleImageSelected(uri: Uri) {
        val bitmap = loadBitmapFromUri(uri)
        if (bitmap != null) {
            val path = saveToTempFile(bitmap)
            finishWithResult(path)
        } else {
            finishWithResult(null)
        }
    }

    private fun finishWithResult(localPath: String?) {
        val data = Intent().putExtra(AtomicImageUploaderPlugin.RESULT_KEY_PATH, localPath ?: "")
        if (localPath != null) {
            setResult(RESULT_OK, data)
        } else {
            setResult(RESULT_CANCELED, data)
        }
        finish()
    }

    // MARK: - Image Processing

    private fun loadBitmapFromUri(uri: Uri): Bitmap? {
        return try {
            val bitmap = decodeSampledBitmap(uri) ?: return null
            val orientation = getExifOrientation(uri)
            applyRotation(bitmap, orientation)
        } catch (e: Throwable) {
            Log.e(TAG, "loadBitmapFromUri failed: ${e.message}")
            null
        }
    }

    private fun decodeSampledBitmap(uri: Uri): Bitmap? {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, options)
        }
        if (options.outWidth <= 0 || options.outHeight <= 0) return null

        options.inSampleSize = calculateInSampleSize(options.outWidth, options.outHeight)
        options.inJustDecodeBounds = false
        return contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, options)
        }
    }

    private fun calculateInSampleSize(width: Int, height: Int): Int {
        val maxSide = max(width, height)
        var inSampleSize = 1
        while (maxSide / inSampleSize > MAX_DIMENSION) {
            inSampleSize *= 2
        }
        return inSampleSize
    }

    private fun getExifOrientation(uri: Uri): Int {
        return try {
            contentResolver.openInputStream(uri)?.use {
                ExifInterface(it).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
                )
            } ?: ExifInterface.ORIENTATION_NORMAL
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
    }

    private fun applyRotation(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.postRotate(90f); matrix.preScale(-1f, 1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.postRotate(270f); matrix.preScale(-1f, 1f) }
            else -> return bitmap
        }
        return try {
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        } catch (e: Exception) {
            bitmap
        }
    }

    private fun saveToTempFile(bitmap: Bitmap): String? {
        return try {
            val tempDir = File(cacheDir, "ImageUploaderTemp")
            if (!tempDir.exists()) tempDir.mkdirs()
            val file = File(tempDir, generateFileName("png"))
            FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "saveToTempFile failed: ${e.message}")
            null
        }
    }
}
