package io.trtc.tuikit.atomicx.albumpicker.util

object DateTimeUtil {
    fun formatTime(timeSeconds: Int): String {
        val second = timeSeconds % 60
        val minuteTemp = timeSeconds / 60
        return if (minuteTemp > 0) {
            val minute = minuteTemp % 60
            val hour = minuteTemp / 60
            if (hour > 0) {
                "${if (hour >= 10) hour.toString() else "0$hour"}:${if (minute >= 10) minute.toString() else "0$minute"}:${if (second >= 10) second.toString() else "0$second"}"
            } else {
                "${if (minute >= 10) minute.toString() else "0$minute"}:${if (second >= 10) second.toString() else "0$second"}"
            }
        } else {
            "00:${if (second >= 10) second.toString() else "0$second"}"
        }
    }
} 