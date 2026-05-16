package com.example.account_book

import android.os.Build
import android.provider.MediaStore
import android.content.ContentValues
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.account_book/file"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val name = call.argument<String>("name") ?: return@setMethodCallHandler result.error("NO_NAME", "missing name", null)
                    val content = call.argument<String>("content") ?: return@setMethodCallHandler result.error("NO_CONTENT", "missing content", null)
                    try {
                        val path = saveToDownloads(name, content)
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(name: String, content: String): String {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, "text/csv")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw Exception("Failed to create file in Downloads")
        resolver.openOutputStream(uri)?.use { os ->
            os.write(content.toByteArray(Charsets.UTF_8))
        } ?: throw Exception("Failed to write file")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val updateValues = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            resolver.update(uri, updateValues, null, null)
        }
        return "/storage/emulated/0/Download/$name"
    }
}
