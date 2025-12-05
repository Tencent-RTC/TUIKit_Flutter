package io.trtc.tuikit.atomicx.basecomponent.utils

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.util.Log

val appContext
    get() = ContextProvider.appContext

class ContextProvider : ContentProvider() {

    companion object {
        @JvmStatic
        lateinit var appContext: Context

        @JvmStatic
        fun init(context: Context) {
            appContext = context.applicationContext
        }
    }

    override fun onCreate(): Boolean {
        if (context == null) {
            Log.e("ContextProvider", "init context is null")
        } else {
            init(context!!)
        }

        return false
    }


    override fun query(
        uri: Uri, projection: Array<String?>?, selection: String?, selectionArgs: Array<String?>?, sortOrder: String?
    ): Cursor? {
        return null
    }

    override fun getType(uri: Uri): String? {
        return null
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        return null
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String?>?): Int {
        return 0
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String?>?): Int {
        return 0
    }
}