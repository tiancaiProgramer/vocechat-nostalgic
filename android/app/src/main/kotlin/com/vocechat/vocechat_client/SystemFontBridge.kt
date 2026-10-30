package com.vocechat.vocechat_client

import android.content.Context
import android.graphics.text.TextRunShaper
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.TextView
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Resolve the fonts Android actually uses, including OEM theme replacements.
 * Only font handles discovered here can be read; Dart cannot supply a path.
 */
internal class SystemFontBridge(context: Context, messenger: BinaryMessenger) {
    private val context = context.applicationContext
    private val channel = MethodChannel(messenger, "vocechat/system_font")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var handles = emptyMap<String, Source>()
    @Volatile private var disposed = false

    private data class Source(
        val id: String,
        val file: File?,
        val modified: Long,
        val size: Long,
        val index: Int,
        val bufferRead: (() -> ByteArray)? = null,
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "describe" -> try {
                    val sources = discover()
                    handles = sources.associateBy { it.id }
                    Log.i(TAG, "resolved fonts=${sources.size} sources=${sources.map { it.file?.name ?: "memory" }}")
                    result.success(sources.map {
                        mapOf("id" to it.id, "size" to it.size, "index" to it.index)
                    })
                } catch (_: Exception) {
                    result.error("font_unavailable", "Cannot resolve the native font", null)
                }
                "read" -> {
                    val source = handles[call.argument<String>("id")]
                    if (source == null) {
                        result.error("font_changed", "Font handle has expired", null)
                    } else worker.execute {
                        try {
                            val data = read(source)
                            main.post { if (!disposed) result.success(data) }
                        } catch (_: Exception) {
                            main.post {
                                if (!disposed) result.error("font_unavailable", "Cannot read the native font", null)
                            }
                        }
                    }
                }
                "loaded" -> {
                    val id = call.argument<String>("id")
                    if (handles.containsKey(id)) Log.i(TAG, "Flutter loaded font=${id?.take(12)}")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun discover(): List<Source> {
        val sources = if (Build.VERSION.SDK_INT >= 31) discoverNative() else discoverLegacy()
        val unique = sources.distinctBy { it.id }.take(2)
        require(unique.sumOf { it.size } <= MAX_TOTAL_BYTES)
        return unique
    }

    @RequiresApi(31)
    private fun discoverNative(): List<Source> {
        val paint = TextView(context).paint
        // Latin and CJK may use different files. Other scripts and emoji keep
        // the platform fallback chain instead of loading the entire font set.
        return listOf("A", "中").mapNotNull { sample ->
            val glyphs = TextRunShaper.shapeTextRun(sample, 0, sample.length,
                0, sample.length, 0f, 0f, false, paint)
            if (glyphs.glyphCount() == 0) null else {
                val font = glyphs.getFont(0)
                val file = font.file?.takeIf { it.isFile && it.canRead() }?.canonicalFile
                val size = file?.length() ?: font.buffer.remaining().toLong()
                require(size in 12..MAX_FONT_BYTES)
                val modified = file?.lastModified() ?: 0L
                val identity = if (file == null) font.sourceIdentifier else 0
                val id = digest("${file?.path}:${size}:${modified}:${font.ttcIndex}:$identity")
                Source(id, file, modified, size, font.ttcIndex) {
                    val buffer = font.buffer.duplicate()
                    ByteArray(buffer.remaining()).also { buffer.get(it) }
                }
            }
        }
    }

    private fun discoverLegacy(): List<Source> {
        // Pre-31 Android has no public API for inspecting a shaped glyph's
        // font. Keep a bounded, read-only fallback for older MIUI devices.
        if (Build.MANUFACTURER.lowercase() !in setOf("xiaomi", "redmi", "poco")) return emptyList()
        val file = File("/data/system/theme/fonts/Roboto-Regular.ttf")
        if (!file.isFile || !file.canRead()) return emptyList()
        val size = file.length()
        require(size in 12..MAX_FONT_BYTES)
        return listOf(Source(digest("${file.path}:$size:${file.lastModified()}:0"),
            file, file.lastModified(), size, 0))
    }

    private fun read(source: Source): ByteArray {
        val file = source.file
        if (file != null) {
            require(file.length() == source.size && file.lastModified() == source.modified)
            val bytes = file.inputStream().use { input ->
                val data = ByteArray(source.size.toInt())
                var offset = 0
                while (offset < data.size) {
                    val count = input.read(data, offset, data.size - offset)
                    require(count > 0)
                    offset += count
                }
                require(input.read() == -1)
                data
            }
            require(file.length() == source.size && file.lastModified() == source.modified)
            return bytes
        }
        return requireNotNull(source.bufferRead).invoke().also {
            require(it.size.toLong() == source.size)
        }
    }

    fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        handles = emptyMap()
        worker.shutdown()
    }

    companion object {
        private const val TAG = "VoceSystemFont"
        private const val MAX_FONT_BYTES = 48L * 1024 * 1024
        private const val MAX_TOTAL_BYTES = 64L * 1024 * 1024
        private fun digest(value: String): String = MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray()).joinToString("") { "%02x".format(it) }
    }
}
