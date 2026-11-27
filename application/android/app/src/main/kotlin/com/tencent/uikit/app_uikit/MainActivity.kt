package com.tencent.uikit.app_uikit

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private fun logs(): List<File> {
        val roots = listOfNotNull(filesDir, cacheDir, getExternalFilesDir(null), externalCacheDir)
        return roots.flatMap { root -> root.walkTopDown().onEnter { it.canonicalPath != File(cacheDir, "log-share").canonicalPath }.maxDepth(6).filter { file ->
            file.isFile && file.extension.lowercase() in setOf("log", "xlog", "clog")
        }.toList() }.distinctBy { it.canonicalPath }.sortedByDescending { it.lastModified() }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tencent.app_uikit/logs").setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> Thread {
                    try {
                        val entries = logs().map { mapOf("name" to it.name, "path" to it.canonicalPath) }
                        runOnUiThread { result.success(entries) }
                    } catch (error: Exception) { runOnUiThread { result.error("logs", error.message, null) } }
                }.start()
                "share" -> try {
                    val path = call.arguments as? String
                    val source = logs().firstOrNull { it.canonicalPath == path }
                    if (source == null) { result.error("missing", "Log file no longer available", null) }
                    else {
                        val directory = File(cacheDir, "log-share").apply { mkdirs() }
                        directory.listFiles()?.forEach { it.delete() }
                        val copy = File(directory, source.name)
                        source.copyTo(copy, overwrite = true)
                        val uri = FileProvider.getUriForFile(this, "$packageName.logshare", copy)
                        startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                            type = "application/octet-stream"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }, null))
                        result.success(null)
                    }
                } catch (error: Exception) { result.error("share", error.message, null) }
                else -> result.notImplemented()
            }
        }
    }
}

class LogShareProvider : FileProvider()
