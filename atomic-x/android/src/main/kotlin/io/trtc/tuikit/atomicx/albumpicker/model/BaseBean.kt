package io.trtc.tuikit.atomicx.albumpicker.model

import android.net.Uri

open class BaseBean : Comparable<BaseBean> {

    var id: Int = 0
    var uri: Uri? = null
    var path: String? = null
    var isFavorite: Boolean = false
    var addTime: Long = 0
    var width: Int = 0
    var height: Int = 0
    var bucketName: String = "0"
    var title: String? = null
    var ownPackageName: String? = null
    var editedUri: Uri? = null
    var isSelected: Boolean = false

    fun getFinalUri(): Uri? {
        return editedUri ?: uri
    }

    override fun compareTo(other: BaseBean): Int {
        if (other == null) {
            return 1
        }
        return other.addTime.compareTo(addTime)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as BaseBean
        return id == other.id
    }

    override fun hashCode(): Int {
        return id
    }
} 