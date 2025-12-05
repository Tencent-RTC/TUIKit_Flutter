package io.trtc.tuikit.atomicx.permission

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Handles the actual permission logic for Android platform.
 * Supports version-specific permission handling for Android 13+ (API 33).
 */
class PermissionHandler(
    private val pluginBinding: FlutterPlugin.FlutterPluginBinding,
) : PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 9527
        
        // Permission identifiers from Dart
        private const val PERMISSION_CAMERA = "camera"
        private const val PERMISSION_MICROPHONE = "microphone"
        private const val PERMISSION_PHOTOS = "photos"
        private const val PERMISSION_STORAGE = "storage"
        private const val PERMISSION_NOTIFICATION = "notification"
    }

    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private var requestedPermissionTypes: List<String>? = null
    private var requestedAndroidPermissions: List<String>? = null

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    /**
     * Convert permission types to actual Android permissions based on OS version
     */
    private fun convertToAndroidPermissions(permissionTypes: List<String>): List<String> {
        val androidPermissions = mutableListOf<String>()
        
        for (type in permissionTypes) {
            when (type) {
                PERMISSION_CAMERA -> {
                    androidPermissions.add(Manifest.permission.CAMERA)
                }
                PERMISSION_MICROPHONE -> {
                    androidPermissions.add(Manifest.permission.RECORD_AUDIO)
                }
                PERMISSION_PHOTOS -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        // Android 14+: Use granular media permissions with partial access support
                        androidPermissions.add(Manifest.permission.READ_MEDIA_IMAGES)
                        androidPermissions.add(Manifest.permission.READ_MEDIA_VIDEO)
                        // READ_MEDIA_VISUAL_USER_SELECTED is checked separately for limited access
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        // Android 13: Use granular media permissions
                        androidPermissions.add(Manifest.permission.READ_MEDIA_IMAGES)
                        androidPermissions.add(Manifest.permission.READ_MEDIA_VIDEO)
                    } else {
                        // Android <13: Use READ_EXTERNAL_STORAGE
                        androidPermissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                    }
                }
                PERMISSION_STORAGE -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        // Android 13+: READ_EXTERNAL_STORAGE for non-media files
                        androidPermissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                    } else {
                        // Android <13: Both read and write permissions
                        androidPermissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                        androidPermissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    }
                }
                PERMISSION_NOTIFICATION -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        androidPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
                    }
                    // Android <13: Notifications don't require runtime permission
                }
            }
        }
        
        return androidPermissions.distinct()
    }
    
    /**
     * Check if photos permission has partial (limited) access on Android 14+
     */
    private fun hasPartialPhotosAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val context = activity ?: pluginBinding.applicationContext
            // Check if READ_MEDIA_VISUAL_USER_SELECTED is granted
            val hasPartialAccess = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            ) == PackageManager.PERMISSION_GRANTED
            
            // Partial access means user selected "Select photos and videos"
            return hasPartialAccess
        }
        return false
    }

    /**
     * Check if all Android permissions for a permission type are granted
     */
    private fun checkPermissionType(permissionType: String): Boolean {
        val androidPermissions = convertToAndroidPermissions(listOf(permissionType))
        if (androidPermissions.isEmpty()) {
            // No runtime permission needed (e.g., notification on Android <13)
            return true
        }
        
        val context = activity ?: pluginBinding.applicationContext
        return androidPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Check if a specific Android permission is permanently denied
     * Note: We need to check if the permission was requested before
     */
    private fun isPermissionPermanentlyDenied(permission: String): Boolean {
        val currentActivity = activity ?: return false
        val context = currentActivity
        
        // If permission is granted, it's not permanently denied
        if (ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED) {
            return false
        }
        
        // If shouldShowRequestPermissionRationale returns true, user can still be asked
        // If it returns false AND permission is not granted, it could be:
        // 1. First time asking (never requested before) - NOT permanently denied
        // 2. User selected "Don't ask again" - IS permanently denied
        // We can't distinguish these cases perfectly, but we assume if this is called
        // after a request, it's case 2
        return !ActivityCompat.shouldShowRequestPermissionRationale(currentActivity, permission)
    }

    /**
     * Get the status of a permission type
     */
    private fun getPermissionTypeStatus(permissionType: String): String {
        val androidPermissions = convertToAndroidPermissions(listOf(permissionType))
        if (androidPermissions.isEmpty()) {
            // No runtime permission needed
            return "granted"
        }
        
        val currentActivity = activity
        val context = currentActivity ?: pluginBinding.applicationContext
        
        // Check if all permissions are granted
        val allGranted = androidPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
        
        if (allGranted) {
            return "granted"
        }
        
        // Android 14+: Check for partial/limited photos access
        if (permissionType == PERMISSION_PHOTOS && hasPartialPhotosAccess()) {
            return "limited"
        }
        
        // For permanently denied check, we need an activity
        // If no activity, we can only return denied
        if (currentActivity == null) {
            return "denied"
        }
        
        // Check if any permission is permanently denied
        // This check is more accurate after a permission request has been made
        val anyPermanentlyDenied = androidPermissions.any { permission ->
            val isGranted = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
            val shouldShow = ActivityCompat.shouldShowRequestPermissionRationale(currentActivity, permission)
            
            // Permanently denied if:
            // - Permission is not granted AND
            // - shouldShowRequestPermissionRationale returns false AND
            // - This permission was in our last request (to avoid false positives on first check)
            !isGranted && !shouldShow && (requestedAndroidPermissions?.contains(permission) == true)
        }
        
        if (anyPermanentlyDenied) {
            return "permanentlyDenied"
        }
        
        return "denied"
    }

    fun requestPermissions(permissionTypes: List<String>, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        val androidPermissions = convertToAndroidPermissions(permissionTypes)
        
        if (androidPermissions.isEmpty()) {
            // No runtime permission needed, return granted for all
            val resultMap = permissionTypes.associateWith { "granted" }
            result.success(resultMap)
            return
        }

        requestedPermissionTypes = permissionTypes
        requestedAndroidPermissions = androidPermissions
        pendingResult = result
        
        ActivityCompat.requestPermissions(
            currentActivity,
            androidPermissions.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }

    fun openAppSettings(): Boolean {
        return try {
            val currentActivity = activity ?: return false
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", currentActivity.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            currentActivity.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun getPermissionStatus(permissionType: String): String {
        return getPermissionTypeStatus(permissionType)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false
        }

        val result = pendingResult ?: return false
        val permissionTypes = requestedPermissionTypes

        if (permissionTypes == null || permissionTypes.isEmpty()) {
            result.error("INTERNAL_ERROR", "No pending permission request", null)
            clearPendingRequest()
            return true
        }

        // Build result map based on permission types
        val resultMap = mutableMapOf<String, String>()
        for (permissionType in permissionTypes) {
            resultMap[permissionType] = getPermissionTypeStatus(permissionType)
        }
        
        result.success(resultMap)
        clearPendingRequest()
        return true
    }

    fun dispose() {
        clearPendingRequest()
    }

    private fun clearPendingRequest() {
        pendingResult = null
        requestedPermissionTypes = null
        requestedAndroidPermissions = null
    }
}
