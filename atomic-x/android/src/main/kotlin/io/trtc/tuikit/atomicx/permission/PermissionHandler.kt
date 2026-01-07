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
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 9528
        
        // Permission identifiers from Dart
        private const val PERMISSION_CAMERA = "camera"
        private const val PERMISSION_MICROPHONE = "microphone"
        private const val PERMISSION_PHOTOS = "photos"
        private const val PERMISSION_STORAGE = "storage"
        private const val PERMISSION_NOTIFICATION = "notification"
        private const val PERMISSION_SYSTEM_ALERT_WINDOW = "systemAlertWindow"
        private const val PERMISSION_DISPLAY_OVER_OTHER_APPS = "displayOverOtherApps"
    }

    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private var requestedPermissionTypes: List<String>? = null
    private var requestedAndroidPermissions: List<String>? = null
    private var pendingOverlayPermissionTypes: List<String>? = null

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
                PERMISSION_SYSTEM_ALERT_WINDOW, PERMISSION_DISPLAY_OVER_OTHER_APPS -> {
                    // These permissions are handled separately via Settings.canDrawOverlays()
                    // Don't add to androidPermissions list
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
     * Check if overlay/system alert window permission is granted
     */
    private fun canDrawOverlays(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val context = activity ?: pluginBinding.applicationContext
            return Settings.canDrawOverlays(context)
        }
        // Below Android M, this permission is granted by default
        return true
    }

    /**
     * Check if permission type is overlay permission
     */
    private fun isOverlayPermission(permissionType: String): Boolean {
        return permissionType == PERMISSION_SYSTEM_ALERT_WINDOW || 
               permissionType == PERMISSION_DISPLAY_OVER_OTHER_APPS
    }

    /**
     * Get the status of a permission type
     */
    private fun getPermissionTypeStatus(permissionType: String): String {
        // Handle overlay permissions separately
        if (isOverlayPermission(permissionType)) {
            return if (canDrawOverlays()) "granted" else "denied"
        }
        
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

        // Separate overlay permissions from regular permissions
        val (overlayPermissions, regularPermissions) = permissionTypes.partition { isOverlayPermission(it) }
        
        // If only overlay permissions, handle them directly
        if (regularPermissions.isEmpty() && overlayPermissions.isNotEmpty()) {
            requestOverlayPermission(overlayPermissions, result)
            return
        }
        
        val androidPermissions = convertToAndroidPermissions(regularPermissions)
        
        if (androidPermissions.isEmpty() && overlayPermissions.isEmpty()) {
            // No runtime permission needed, return granted for all
            val resultMap = permissionTypes.associateWith { "granted" }
            result.success(resultMap)
            return
        }

        // If we have overlay permissions, we need to handle them after regular permissions
        if (overlayPermissions.isNotEmpty()) {
            pendingOverlayPermissionTypes = overlayPermissions
        }
        
        requestedPermissionTypes = regularPermissions
        requestedAndroidPermissions = androidPermissions
        pendingResult = result
        
        if (androidPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                currentActivity,
                androidPermissions.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        } else {
            // Only overlay permissions left
            requestOverlayPermission(overlayPermissions, result)
        }
    }
    
    /**
     * Request overlay permission by opening system settings
     */
    private fun requestOverlayPermission(overlayPermissions: List<String>, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }
        
        // Check if already granted or if below Android M
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(currentActivity)) {
            val resultMap = overlayPermissions.associateWith { "granted" }
            result.success(resultMap)
            return
        }
        
        // Need to request permission
        try {
            pendingOverlayPermissionTypes = overlayPermissions
            pendingResult = result
            
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${currentActivity.packageName}")
            )
            currentActivity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        } catch (e: Exception) {
            // If opening settings fails, return denied status
            val resultMap = overlayPermissions.associateWith { "denied" }
            result.success(resultMap)
            clearPendingRequest()
        }
    }
    
    /**
     * Handle overlay permission result when user returns from settings
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != OVERLAY_PERMISSION_REQUEST_CODE) {
            return false
        }
        
        val result = pendingResult ?: return false
        val overlayPermissions = pendingOverlayPermissionTypes
        
        if (overlayPermissions.isNullOrEmpty()) {
            result.error("INTERNAL_ERROR", "No pending overlay permission request", null)
            clearPendingRequest()
            return true
        }
        
        // Build result map
        val resultMap = buildResultMap(requestedPermissionTypes ?: emptyList(), overlayPermissions)
        
        result.success(resultMap)
        clearPendingRequest()
        return true
    }
    
    /**
     * Build result map for both regular and overlay permissions
     */
    private fun buildResultMap(regularPermissions: List<String>, overlayPermissions: List<String>): Map<String, String> {
        val resultMap = mutableMapOf<String, String>()
        
        // Add regular permissions status
        for (permissionType in regularPermissions) {
            resultMap[permissionType] = getPermissionTypeStatus(permissionType)
        }
        
        // Add overlay permissions status
        val overlayStatus = if (canDrawOverlays()) "granted" else "denied"
        for (permissionType in overlayPermissions) {
            resultMap[permissionType] = overlayStatus
        }
        
        return resultMap
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
        val overlayPermissions = pendingOverlayPermissionTypes

        if (permissionTypes.isNullOrEmpty()) {
            result.error("INTERNAL_ERROR", "No pending permission request", null)
            clearPendingRequest()
            return true
        }

        // If we have pending overlay permissions, request them now
        if (!overlayPermissions.isNullOrEmpty()) {
            requestOverlayPermissionAfterRegular(permissionTypes, overlayPermissions, result)
            return true
        }

        // Build result map based on permission types
        val resultMap = permissionTypes.associateWith { getPermissionTypeStatus(it) }
        
        result.success(resultMap)
        clearPendingRequest()
        return true
    }
    
    /**
     * Request overlay permission after regular permissions are handled
     */
    private fun requestOverlayPermissionAfterRegular(
        regularPermissions: List<String>,
        overlayPermissions: List<String>,
        result: MethodChannel.Result
    ) {
        val currentActivity = activity
        if (currentActivity == null) {
            // Merge results and return
            val resultMap = buildResultMap(regularPermissions, overlayPermissions)
            result.success(resultMap)
            clearPendingRequest()
            return
        }
        
        // Check if already granted or below Android M
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(currentActivity)) {
            val resultMap = buildResultMap(regularPermissions, overlayPermissions)
            result.success(resultMap)
            clearPendingRequest()
            return
        }
        
        // Need to request overlay permission
        try {
            // Store regular results
            requestedPermissionTypes = regularPermissions
            pendingOverlayPermissionTypes = overlayPermissions
            pendingResult = result
            
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${currentActivity.packageName}")
            )
            currentActivity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        } catch (e: Exception) {
            // Merge results and return
            val resultMap = buildResultMap(regularPermissions, overlayPermissions)
            result.success(resultMap)
            clearPendingRequest()
        }
    }

    fun dispose() {
        clearPendingRequest()
    }

    private fun clearPendingRequest() {
        pendingResult = null
        requestedPermissionTypes = null
        requestedAndroidPermissions = null
        pendingOverlayPermissionTypes = null
    }
}
