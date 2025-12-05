package io.trtc.tuikit.atomicx.basecomponent.theme

import android.os.Parcelable
import android.util.Log
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.graphics.Color
import com.tencent.mmkv.MMKV
import io.trtc.tuikit.atomicx.basecomponent.config.AppBuilderConfig
import io.trtc.tuikit.atomicx.basecomponent.utils.appContext
import kotlinx.parcelize.Parcelize
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

enum class ThemeMode {
    SYSTEM, LIGHT, DARK
}

@Parcelize
@Serializable
data class ThemeConfig(
    val mode: ThemeMode,
    val primaryColor: String?
) : Parcelable

val LocalTheme = compositionLocalOf { ThemeState.shared }

class ThemeState {
    companion object {
        private const val THEME_KEY = "BaseComponentThemeKey"
        private val json = Json { ignoreUnknownKeys = true }
        val shared = ThemeState()
    }

    private constructor()

    private var _currentTheme = mutableStateOf(ThemeConfig(ThemeMode.SYSTEM, null))

    private var cachedColorScheme: ColorScheme? = null
    private var cachedThemeConfig: ThemeConfig? = null

    init {
        MMKV.initialize(appContext)
        loadTheme()
    }

    val currentTheme: ThemeConfig
        get() = _currentTheme.value

    val currentMode: ThemeMode
        get() = _currentTheme.value.mode

    val currentPrimaryColor: String?
        get() = _currentTheme.value.primaryColor

    val hasCustomPrimaryColor: Boolean
        get() = _currentTheme.value.primaryColor != null

    val isDarkMode: Boolean
        @Composable
        get() = when (currentMode) {
            ThemeMode.DARK -> true
            ThemeMode.LIGHT -> false
            ThemeMode.SYSTEM -> isSystemInDarkTheme()
        }

    fun setThemeMode(mode: ThemeMode) {
        clearCache()
        _currentTheme.value = ThemeConfig(mode, _currentTheme.value.primaryColor)
        saveTheme()
    }

    fun setPrimaryColor(hexColor: String) {
        if (!hexColor.matches(Regex("^#[0-9A-Fa-f]{6}$"))) {
            Log.w("ThemeState", "Invalid hex color format: $hexColor")
            return
        }
        clearCache()
        _currentTheme.value = ThemeConfig(_currentTheme.value.mode, hexColor)
        saveTheme()
    }

    fun clearPrimaryColor() {
        clearCache()
        _currentTheme.value = ThemeConfig(_currentTheme.value.mode, null)
        saveTheme()
    }

    private fun loadTheme() {

        val jsonString = MMKV.mmkvWithID("BaseComponentID").decodeString(THEME_KEY)
        if (!jsonString.isNullOrEmpty()) {
            try {
                val theme = json.decodeFromString(ThemeConfig.serializer(), jsonString)
                _currentTheme.value = theme
                return
            } catch (e: Exception) {
                Log.e("ThemeState", "Failed to load theme: ${e.message}")
            }
        }
        val config = AppBuilderConfig
        val mode = when (config.themeMode) {
            ThemeMode.LIGHT -> ThemeMode.LIGHT
            ThemeMode.DARK -> ThemeMode.DARK
            else -> ThemeMode.SYSTEM
        }

        var primaryColor: String? = null
        if (config.primaryColor.isNotEmpty() && config.primaryColor.matches(Regex("^#[0-9A-Fa-f]{6}$"))) {
            primaryColor = config.primaryColor
        }

        _currentTheme.value = ThemeConfig(mode, primaryColor)
    }

    private fun saveTheme() {
        try {
            val jsonString = json.encodeToString(ThemeConfig.serializer(), _currentTheme.value)
            MMKV.mmkvWithID("BaseComponentID").encode(THEME_KEY, jsonString)
        } catch (e: Exception) {
            Log.e("ThemeState", "Failed to save theme: ${e.message}")
        }
    }

    private fun clearCache() {
        cachedColorScheme = null
        cachedThemeConfig = null
    }

    val colors: ColorScheme
        @Composable get() {
            if (cachedColorScheme != null && cachedThemeConfig == _currentTheme.value) {
                return cachedColorScheme!!
            }

            val newColorScheme = calculateColorScheme()
            cachedColorScheme = newColorScheme
            cachedThemeConfig = _currentTheme.value

            return newColorScheme
        }

    val fonts: FontScheme
        @Composable get() = DefaultFontScheme

    val radius: RadiusScheme
        @Composable get() = DefaultRadiusScheme

    val spacings: SpacingScheme
        @Composable get() = DefaultSpacingScheme

    @Composable
    private fun calculateColorScheme(): ColorScheme {
        val effectiveMode = when (currentMode) {
            ThemeMode.SYSTEM -> if (isSystemInDarkTheme()) ThemeMode.DARK else ThemeMode.LIGHT
            else -> currentMode
        }

        return if (_currentTheme.value.primaryColor != null) {
            val primary = ThemeColorGenerator.hexToColor(_currentTheme.value.primaryColor!!)
            getCustomScheme(
                isLight = effectiveMode == ThemeMode.LIGHT,
                baseScheme = if (effectiveMode == ThemeMode.LIGHT) LightColorScheme else DarkColorScheme,
                primary = primary
            )
        } else {
            when (effectiveMode) {
                ThemeMode.LIGHT -> LightColorScheme
                ThemeMode.DARK -> DarkColorScheme
                ThemeMode.SYSTEM -> getSystemScheme()
            }
        }
    }

    @Composable
    private fun getSystemScheme(): ColorScheme {
        return if (isSystemInDarkTheme()) DarkColorScheme else LightColorScheme
    }

    private fun getCustomScheme(isLight: Boolean, baseScheme: ColorScheme, primary: Color): ColorScheme {
        val hexColor = ThemeColorGenerator.colorToHex(primary)
        val lightPalette = ThemeColorGenerator.generateColorPalette(hexColor, "light")
        val darkPalette = ThemeColorGenerator.generateColorPalette(hexColor, "dark")

        val themeLight1 = ThemeColorGenerator.hexToColor(lightPalette[0])
        val themeLight2 = ThemeColorGenerator.hexToColor(lightPalette[1])
        val themeLight5 = ThemeColorGenerator.hexToColor(lightPalette[4])
        val themeLight6 = ThemeColorGenerator.hexToColor(lightPalette[5])
        val themeLight7 = ThemeColorGenerator.hexToColor(lightPalette[6])
        val themeDark2 = ThemeColorGenerator.hexToColor(darkPalette[1])
        val themeDark5 = ThemeColorGenerator.hexToColor(darkPalette[4])
        val themeDark6 = ThemeColorGenerator.hexToColor(darkPalette[5])
        val themeDark7 = ThemeColorGenerator.hexToColor(darkPalette[6])

        return baseScheme.copy(
            textColorLink = if (isLight) themeLight6 else themeDark6,
            textColorLinkHover = if (isLight) themeLight5 else themeDark5,
            textColorLinkActive = if (isLight) themeLight7 else themeDark7,
            textColorLinkDisabled = if (isLight) themeLight2 else themeDark2,
            bgColorBubbleOwn = if (isLight) themeLight2 else themeDark7,
            bgColorAvatar = if (isLight) themeLight2 else themeDark2,
            listColorFocused = if (isLight) themeLight1 else themeDark2,
            buttonColorPrimaryDefault = if (isLight) themeLight6 else themeDark6,
            buttonColorPrimaryHover = if (isLight) themeLight5 else themeDark5,
            buttonColorPrimaryActive = if (isLight) themeLight7 else themeDark7,
            buttonColorPrimaryDisabled = if (isLight) themeLight2 else themeDark2,
            dropdownColorActive = if (isLight) themeLight1 else themeDark2,
            checkboxColorSelected = if (isLight) themeLight6 else themeDark5,
            toastColorDefault = if (isLight) themeLight1 else themeDark2,
            switchColorOn = if (isLight) themeLight6 else themeDark5,
            sliderColorFilled = if (isLight) themeLight6 else themeDark5,
            tabColorSelected = if (isLight) themeLight2 else themeDark5,
        )
    }

}

object ThemeColorGenerator {

    fun generateColorPalette(baseColor: String, theme: String): List<String> {
        return if (isStandardColor(baseColor)) {
            val palette = getClosestPalette(baseColor)
            palette[theme] ?: palette["light"]!!
        } else {
            generateDynamicColorVariations(baseColor, theme)
        }
    }

    fun hexToColor(hex: String): Color {
        val cleanHex = hex.removePrefix("#")
        val colorInt = cleanHex.toLong(16)

        val r = ((colorInt shr 16) and 0xFF) / 255f
        val g = ((colorInt shr 8) and 0xFF) / 255f
        val b = (colorInt and 0xFF) / 255f

        return Color(r, g, b)
    }

    fun colorToHex(color: Color): String {
        val r = (color.red * 255).toInt()
        val g = (color.green * 255).toInt()
        val b = (color.blue * 255).toInt()

        return "#%02X%02X%02X".format(r, g, b)
    }

    private val BLUE_PALETTE = mapOf(
        "light" to listOf(
            "#ebf3ff", "#cce2ff", "#adcfff", "#7aafff", "#4588f5",
            "#1c66e5", "#0d49bf", "#033099", "#001f73", "#00124d"
        ),
        "dark" to listOf(
            "#1c2333", "#243047", "#2f4875", "#305ba6", "#2b6ad6",
            "#4086ff", "#5c9dff", "#78b0ff", "#9cc7ff", "#c2deff"
        )
    )

    private val GREEN_PALETTE = mapOf(
        "light" to listOf(
            "#dcfae9", "#b6f0d1", "#84e3b5", "#5ad69e", "#3cc98c",
            "#0abf77", "#09a768", "#078f59", "#067049", "#044d37"
        ),
        "dark" to listOf(
            "#1a2620", "#22352c", "#2f4f3f", "#377355", "#368f65",
            "#38a673", "#62b58b", "#8bc7a9", "#a9d4bd", "#c8e5d5"
        )
    )

    private val RED_PALETTE = mapOf(
        "light" to listOf(
            "#ffe7e6", "#fcc9c7", "#faaeac", "#f58989", "#e86666",
            "#e54545", "#c93439", "#ad2934", "#8f222d", "#6b1a27"
        ),
        "dark" to listOf(
            "#2b1c1f", "#422324", "#613234", "#8a4242", "#c2544e",
            "#e6594c", "#e57a6e", "#f3a599", "#facbc3", "#fae4de"
        )
    )

    private val ORANGE_PALETTE = mapOf(
        "light" to listOf(
            "#ffeedb", "#ffd6b2", "#ffbe85", "#ffa455", "#ff8b2b",
            "#ff7200", "#e05d00", "#bf4900", "#8f370b", "#662200"
        ),
        "dark" to listOf(
            "#211a19", "#35231a", "#462e1f", "#653c21", "#96562a",
            "#e37f32", "#e39552", "#eead72", "#f7cfa4", "#f9e9d1"
        )
    )

    private val HSL_ADJUSTMENTS = mapOf(
        "light" to mapOf(
            1 to Pair(-40.0, 45.0),
            2 to Pair(-30.0, 35.0),
            3 to Pair(-20.0, 25.0),
            4 to Pair(-10.0, 15.0),
            5 to Pair(-5.0, 5.0),
            6 to Pair(0.0, 0.0),
            7 to Pair(5.0, -10.0),
            8 to Pair(10.0, -20.0),
            9 to Pair(15.0, -30.0),
            10 to Pair(20.0, -40.0)
        ),
        "dark" to mapOf(
            1 to Pair(-60.0, -35.0),
            2 to Pair(-50.0, -25.0),
            3 to Pair(-40.0, -15.0),
            4 to Pair(-30.0, -5.0),
            5 to Pair(-20.0, 5.0),
            6 to Pair(0.0, 0.0),
            7 to Pair(-10.0, 15.0),
            8 to Pair(-20.0, 30.0),
            9 to Pair(-30.0, 45.0),
            10 to Pair(-40.0, 60.0)
        )
    )

    private fun getClosestPalette(color: String): Map<String, List<String>> {
        val hsl = hexToHSL(color)

        val palettes = listOf(
            BLUE_PALETTE to BLUE_PALETTE["light"]!![5],
            GREEN_PALETTE to GREEN_PALETTE["light"]!![5],
            RED_PALETTE to RED_PALETTE["light"]!![5],
            ORANGE_PALETTE to ORANGE_PALETTE["light"]!![5]
        )

        val distances = palettes.map { (palette, baseColor) ->
            palette to colorDistance(hsl, hexToHSL(baseColor))
        }

        return distances.minByOrNull { it.second }?.first ?: BLUE_PALETTE
    }

    private fun isStandardColor(color: String): Boolean {
        val standardColors = listOf(
            BLUE_PALETTE["light"]!![5],
            GREEN_PALETTE["light"]!![5],
            RED_PALETTE["light"]!![5],
            ORANGE_PALETTE["light"]!![5]
        )

        val inputHsl = hexToHSL(color)
        return standardColors.any { standardColor ->
            val standardHsl = hexToHSL(standardColor)
            val dh = min(abs(inputHsl.first - standardHsl.first), 360 - abs(inputHsl.first - standardHsl.first))
            dh < 15 && abs(inputHsl.second - standardHsl.second) < 15 && abs(inputHsl.third - standardHsl.third) < 15
        }
    }

    private fun adjustColor(color: String, adjustment: Pair<Double, Double>): String {
        val hsl = hexToHSL(color)
        val newS = max(0.0, min(100.0, hsl.second + adjustment.first))
        val newL = max(0.0, min(100.0, hsl.third + adjustment.second))
        return hslToHex(hsl.first, newS, newL)
    }

    private fun generateDynamicColorVariations(baseColor: String, theme: String): List<String> {
        val variations = mutableListOf<String>()
        val adjustments = HSL_ADJUSTMENTS[theme] ?: HSL_ADJUSTMENTS["light"]!!
        val baseHsl = hexToHSL(baseColor)
        val saturationFactor = when {
            baseHsl.second > 70 -> 0.8
            baseHsl.second < 30 -> 1.2
            else -> 1.0
        }
        val lightnessFactor = when {
            baseHsl.third > 70 -> 0.8
            baseHsl.third < 30 -> 1.2
            else -> 1.0
        }

        for (i in 1..10) {
            val adjustment = adjustments[i] ?: Pair(0.0, 0.0)
            val adjustedS = adjustment.first * saturationFactor
            val adjustedL = adjustment.second * lightnessFactor
            variations.add(adjustColor(baseColor, Pair(adjustedS, adjustedL)))
        }

        return variations
    }

    private fun colorDistance(c1: Triple<Double, Double, Double>, c2: Triple<Double, Double, Double>): Double {
        val dh = min(abs(c1.first - c2.first), 360 - abs(c1.first - c2.first))
        val ds = c1.second - c2.second
        val dl = c1.third - c2.third
        return sqrt(dh * dh + ds * ds + dl * dl)
    }

    private fun hexToHSL(hex: String): Triple<Double, Double, Double> {
        val cleanHex = hex.removePrefix("#")
        val colorInt = cleanHex.toLong(16)

        val r = ((colorInt shr 16) and 0xFF) / 255.0
        val g = ((colorInt shr 8) and 0xFF) / 255.0
        val b = (colorInt and 0xFF) / 255.0

        val maxVal = maxOf(r, g, b)
        val minVal = minOf(r, g, b)
        var h = 0.0
        var s = 0.0
        val l = (maxVal + minVal) / 2.0

        if (maxVal != minVal) {
            val d = maxVal - minVal
            s = if (l > 0.5) d / (2.0 - maxVal - minVal) else d / (maxVal + minVal)

            h = when (maxVal) {
                r -> (g - b) / d + (if (g < b) 6.0 else 0.0)
                g -> (b - r) / d + 2.0
                b -> (r - g) / d + 4.0
                else -> 0.0
            }
            h /= 6.0
        }

        return Triple(h * 360.0, s * 100.0, l * 100.0)
    }

    private fun hslToHex(h: Double, s: Double, l: Double): String {
        val hNorm = h / 360.0
        val sNorm = s / 100.0
        val lNorm = l / 100.0

        val c = (1.0 - abs(2.0 * lNorm - 1.0)) * sNorm
        val x = c * (1.0 - abs((hNorm * 6.0) % 2.0 - 1.0))
        val m = lNorm - c / 2.0

        val (r, g, b) = when ((hNorm * 6.0).toInt()) {
            0 -> Triple(c, x, 0.0)
            1 -> Triple(x, c, 0.0)
            2 -> Triple(0.0, c, x)
            3 -> Triple(0.0, x, c)
            4 -> Triple(x, 0.0, c)
            5 -> Triple(c, 0.0, x)
            else -> Triple(0.0, 0.0, 0.0)
        }

        val red = ((r + m) * 255.0).toInt()
        val green = ((g + m) * 255.0).toInt()
        val blue = ((b + m) * 255.0).toInt()

        return "#%02X%02X%02X".format(red, green, blue)
    }
}
