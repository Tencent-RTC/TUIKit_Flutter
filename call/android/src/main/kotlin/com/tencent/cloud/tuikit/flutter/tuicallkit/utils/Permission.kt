package com.tencent.cloud.tuikit.flutter.tuicallkit.utils

import com.tencent.qcloud.tuicore.TUIConfig

object Permission {
     fun hasPermission(premission: kotlin.String): kotlin.Boolean {
        return com.tencent.qcloud.tuicore.permission.PermissionRequester.newInstance(premission).has()
    }

    fun requestFloatPermission() {
        if (com.tencent.qcloud.tuicore.permission.PermissionRequester.newInstance(com.tencent.qcloud.tuicore.permission.PermissionRequester.FLOAT_PERMISSION).has()) {
            return
        }
        //In TUICallKit,Please open both OverlayWindows and Background pop-ups permission.
        com.tencent.qcloud.tuicore.permission.PermissionRequester.newInstance(com.tencent.qcloud.tuicore.permission.PermissionRequester.FLOAT_PERMISSION, com.tencent.qcloud.tuicore.permission.PermissionRequester.BG_START_PERMISSION)
            .request()
    }

    val isNotificationEnabled: Boolean
        get() {
            val context: android.content.Context = TUIConfig.getAppContext()
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                // For Android Oreo and above
                val manager: android.app.NotificationManager = context.getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                return manager.areNotificationsEnabled()
            }
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                // For versions prior to Android Oreo
                var appOps: android.app.AppOpsManager? = null
                appOps = context.getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager?
                val appInfo: android.content.pm.ApplicationInfo = context.getApplicationInfo()
                val packageName: kotlin.String? = context.getApplicationContext().getPackageName()
                val uid: kotlin.Int = appInfo.uid
                try {
                    var appOpsClass: java.lang.Class<*>? = null
                    appOpsClass = java.lang.Class.forName(android.app.AppOpsManager::class.java.getName())
                    val checkOpNoThrowMethod: java.lang.reflect.Method = appOpsClass.getMethod(
                        "checkOpNoThrow", java.lang.Integer.TYPE, java.lang.Integer.TYPE, kotlin.String::class.java
                    )
                    val opPostNotificationValue: java.lang.reflect.Field = appOpsClass.getDeclaredField("OP_POST_NOTIFICATION")
                    val value: kotlin.Int = opPostNotificationValue.get(kotlin.Int::class.java) as kotlin.Int
                    return checkOpNoThrowMethod.invoke(appOps, value, uid, packageName) as kotlin.Int == android.app.AppOpsManager.MODE_ALLOWED
                }catch (e: java.lang.Exception) {
                    e.printStackTrace()
                }
            }
            return false
        }
}