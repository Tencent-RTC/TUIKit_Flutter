package io.trtc.tuikit.atomicx.utils

import android.app.Activity
import android.app.Application
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Log
import java.util.Locale

/**
 * Language setting utility class
 * Used to dynamically set the locale when an Activity starts.
 */
object LocaleUtils {
    private const val TAG = "LocaleUtils"

    /**
     * Create a Locale object
     *
     * @param languageCode Language code, such as "en", "zh"
     * @param countryCode Country/region code, such as "US", "CN", optional
     * @param scriptCode Text code, such as "Hant" (Traditional Chinese), optional
     * @return Locale object
     */
    fun createLocale(languageCode: String, countryCode: String? = null, scriptCode: String? = null): Locale {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !scriptCode.isNullOrEmpty()) {
            // Android 5.0 and above support script code (such as Hant for Traditional Chinese).
            Locale.Builder()
                .setLanguage(languageCode)
                .apply {
                    if (!countryCode.isNullOrEmpty()) setRegion(countryCode)
                    if (!scriptCode.isNullOrEmpty()) setScript(scriptCode)
                }
                .build()
        } else if (!countryCode.isNullOrEmpty()) {
            Locale(languageCode, countryCode)
        } else {
            Locale(languageCode)
        }
    }

    /**
     * Set the application language for the Activity
     *
     * @param activity Target Activity
     * @param languageCode Language code
     * @param countryCode Country/region code, optional
     * @param scriptCode Text code, optional
     */
    fun applyLanguageToActivity(
        activity: Activity,
        languageCode: String,
        countryCode: String? = null,
        scriptCode: String? = null
    ) {
        try {
            val locale = createLocale(languageCode, countryCode, scriptCode)
            val resources = activity.resources
            val configuration = Configuration(resources.configuration)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                configuration.setLocale(locale)
            } else {
                @Suppress("DEPRECATION")
                configuration.locale = locale
            }

            @Suppress("DEPRECATION")
            resources.updateConfiguration(configuration, resources.displayMetrics)

            Log.d(TAG, "Language applied to ${activity.javaClass.simpleName}: ${locale.toLanguageTag()}")
        } catch (e: Exception) {
            Log.e(TAG, "Error applying language to activity", e)
        }
    }

    /**
     * Creates Activity lifecycle callbacks to automatically set the language when a specific Activity is created.
     *
     * @param targetActivityClass The Class of the target Activity
     * @param languageCode 语The language code
     * @param countryCode The country/region code, optional
     * @param scriptCode The script code, optional
     * @param onActivityDestroyed The callback when the Activity is destroyed, optional
     * @return ActivityLifecycleCallbacks object
     */
    fun createLanguageCallback(
        targetActivityClass: Class<out Activity>,
        languageCode: String,
        countryCode: String? = null,
        scriptCode: String? = null,
        onActivityDestroyed: (() -> Unit)? = null
    ): Application.ActivityLifecycleCallbacks {
        return object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                if (targetActivityClass.isInstance(activity)) {
                    Log.d(TAG, "${activity.javaClass.simpleName} created, applying language: $languageCode")
                    applyLanguageToActivity(activity, languageCode, countryCode, scriptCode)
                }
            }

            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {
                if (targetActivityClass.isInstance(activity)) {
                    Log.d(TAG, "${activity.javaClass.simpleName} destroyed")
                    onActivityDestroyed?.invoke()
                }
            }
        }
    }

    /**
     * Registration language setting callback
     *
     * @param application Application object
     * @param targetActivityClass The Class of the target Activity
     * @param languageCode Language code
     * @param countryCode The country/region code, optional
     * @param scriptCode The script code, optional
     * @param onActivityDestroyed Callback when the Activity is destroyed, optional
     * @return ActivityLifecycleCallbacks object, used for subsequent unregistration
     */
    fun registerLanguageCallback(
        application: Application,
        targetActivityClass: Class<out Activity>,
        languageCode: String,
        countryCode: String? = null,
        scriptCode: String? = null,
        onActivityDestroyed: (() -> Unit)? = null
    ): Application.ActivityLifecycleCallbacks {
        val callback = createLanguageCallback(
            targetActivityClass,
            languageCode,
            countryCode,
            scriptCode,
            onActivityDestroyed
        )
        application.registerActivityLifecycleCallbacks(callback)
        Log.d(TAG, "Language callback registered for ${targetActivityClass.simpleName}")
        return callback
    }

    /**
     * Unregister language settings callback
     *
     * @param application Application object
     * @param callback The ActivityLifecycleCallbacks object to unregister
     */
    fun unregisterLanguageCallback(
        application: Application,
        callback: Application.ActivityLifecycleCallbacks?
    ) {
        callback?.let {
            application.unregisterActivityLifecycleCallbacks(it)
            Log.d(TAG, "Language callback unregistered")
        }
    }
}
