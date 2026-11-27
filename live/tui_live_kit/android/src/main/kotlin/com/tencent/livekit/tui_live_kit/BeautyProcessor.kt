package com.tencent.livekit.tui_live_kit

import android.content.Context
import com.google.gson.Gson
import com.tencent.effect.beautykit.TEBeautyKit
import com.tencent.effect.beautykit.config.TEUIConfig
import com.tencent.effect.beautykit.model.TEPanelDataModel
import com.tencent.effect.beautykit.model.TEUIProperty
import com.tencent.effect.beautykit.provider.TEGeneralDataProvider
import com.tencent.effect.beautykit.view.panelview.TEPanelView
import com.tencent.effect.beautykit.view.panelview.TEPanelViewCallback
import java.util.Locale
import org.json.JSONArray

/** Owns one account's effects; creation and destruction run on TRTC's GL thread. */
internal class BeautyProcessor(private val context: Context, private val key: String) {
    private val preferences = context.getSharedPreferences("livekit_advanced_beauty", Context.MODE_PRIVATE)
    private val lock = Any()
    private var kit: TEBeautyKit? = null
    private var accepting = true
    private val initial: String

    init {
        val stored = preferences.getString(key, null)?.takeIf { runCatching { JSONArray(it) }.isSuccess }
        val defaults = provider().apply { getPanelData(context) }
        initial = stored?.replace(MARKER, TEBeautyKit.getResPath()) ?: Gson().toJson(defaults.usedProperties)
    }

    fun create(): Boolean = synchronized(lock) {
        if (!accepting) return false
        runCatching {
            @Suppress("DEPRECATION") val engine = TEBeautyKit(context)
            kit = engine
            engine.setMute(true)
            engine.setLastParamList(
                preferences.getString(key, null)?.replace(MARKER, TEBeautyKit.getResPath()) ?: initial
            )
            engine.onResume()
        }.isSuccess
    }

    fun process(texture: Int, width: Int, height: Int): Int = synchronized(lock) {
        if (!accepting) return texture
        val output = kit?.process(texture, width, height) ?: texture
        check(output > 0)
        output
    }

    fun stop() = synchronized(lock) {
        save()
        accepting = false
        kit?.onPause()
    }

    fun destroy() = synchronized(lock) {
        kit?.onDestroy()
        kit = null
    }

    fun save() = synchronized(lock) {
        val parameters = kit?.exportInUseSDKParam() ?: return
        preferences.edit().putString(key, parameters.replace(TEBeautyKit.getResPath(), MARKER)).apply()
    }

    fun panel(context: Context): TEPanelView? = synchronized(lock) {
        val engine = kit?.takeIf { accepting } ?: return null
        TEUIConfig.getInstance().apply {
            setSystemLocal(Locale.getDefault())
            panelBackgroundColor = 0xFF1F2024.toInt()
        }
        val data = provider().apply { setUsedParams(engine.inUseSDKParamList) }
        TEPanelView(context).apply {
            setLastParamList(engine.exportInUseSDKParam().ifBlank { "[]" })
            setupWithTEBeautyKit(engine)
            showViewWithProvider(data, object : TEPanelViewCallback {
                override fun onClickCustomSeg(property: TEUIProperty) = Unit
                override fun onCameraClick() = Unit
                override fun onTitleClick(property: TEUIProperty) = Unit
                override fun onEffectStateChange(state: TEBeautyKit.EffectState) = Unit
                override fun onUpdateEffected(params: List<TEUIProperty.TESDKParam>) {
                    save()
                }
            })
        }
    }

    private fun provider() = object : TEGeneralDataProvider() {
        override fun isShowCompareBtn() = false
    }.apply {
        val beauty = TEUIProperty.UICategory.BEAUTY
        val motion = TEUIProperty.UICategory.MOTION
        setPanelDataList(
            listOf(
                "beauty_template" to TEUIProperty.UICategory.BEAUTY_TEMPLATE,
                "beauty" to beauty, "beauty_image" to beauty, "beauty_shape" to beauty, "beauty_makeup" to beauty,
                "lut" to TEUIProperty.UICategory.LUT, "beauty_body" to TEUIProperty.UICategory.BODY_BEAUTY,
                "motion_2d" to motion, "motion_3d" to motion, "motion_gesture" to motion,
                "makeup" to TEUIProperty.UICategory.MAKEUP, "light_makeup" to TEUIProperty.UICategory.LIGHT_MAKEUP,
            ).map { (name, category) -> TEPanelDataModel("beauty_panel/$name.json", category) })
    }

    private companion object {
        const val MARKER = "__LIVE_BEAUTY_RES__/"
    }
}
