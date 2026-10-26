package com.vocechat.vocechat_client

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.core.content.IntentCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Imports temporary URI grants off the UI thread; no upload or chat sending.
 * The retained Flutter engine owns this bridge, not any particular Activity.
 */
internal class IncomingShareBridge(context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val app = context.applicationContext
    private val channel = MethodChannel(messenger, "vocechat/incoming_share")
    private val main = Handler(Looper.getMainLooper())
    private val io = ThreadPoolExecutor(1, 2, 30, TimeUnit.SECONDS, ArrayBlockingQueue(4))
    private val root = File(app.cacheDir, "incoming-shares")
    private val pending = linkedMapOf<String, Map<String, Any>>()
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
        io.execute {
            root.mkdirs()
            root.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > TimeUnit.DAYS.toMillis(1) }
                ?.forEach { it.deleteRecursively() }
        }
    }

    fun receive(intent: Intent?) {
        if (disposed || intent?.action !in listOf(Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE)) return
        if (pending.size >= 4) return
        val id = UUID.randomUUID().toString()
        val snapshot = Intent(intent)
        pending[id] = mapOf("id" to id, "text" to "", "files" to emptyList<Any>(), "loading" to true)
        notifyDart()
        val finished = AtomicBoolean(false)
        val deadline = SystemClock.elapsedRealtime() + 20_000
        val future = try {
            io.submit {
                val directory = File(root, id)
                var text = ""
                val files = mutableListOf<Map<String, Any>>()
                var error = ""
                var total = 0L
                try {
                    text = snapshot.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty().take(1_000_000)
                    val uris = mutableListOf<Uri>()
                    if (snapshot.action == Intent.ACTION_SEND_MULTIPLE) {
                        uris.addAll(IntentCompat.getParcelableArrayListExtra(snapshot, Intent.EXTRA_STREAM, Uri::class.java).orEmpty())
                    } else {
                        IntentCompat.getParcelableExtra(snapshot, Intent.EXTRA_STREAM, Uri::class.java)?.let { uris.add(it) }
                    }
                    snapshot.clipData?.let { clip ->
                        for (index in 0 until minOf(clip.itemCount, 17)) clip.getItemAt(index).uri?.let { uris.add(it) }
                    }
                    val distinct = uris.distinct()
                    if (distinct.size > 16) error = "too_large"
                    for ((index, uri) in distinct.take(16).withIndex()) {
                        if (Thread.currentThread().isInterrupted || SystemClock.elapsedRealtime() > deadline) throw IOException()
                        var destination: File? = null
                        try {
                            // file:// and our own FileProvider must never be used
                            // to turn an external intent into a private-file read.
                            if (uri.scheme != "content" || uri.authority?.startsWith(app.packageName) == true) throw IOException()
                            val mime = app.contentResolver.getType(uri).orEmpty()
                            var name = ""
                            app.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                                if (cursor.moveToFirst()) name = cursor.getString(0).orEmpty()
                            }
                            name = name.substringAfterLast('/').substringAfterLast('\\')
                                .replace(Regex("[\\p{Cntrl}]"), "_").take(160)
                            if (name.isBlank() || name == "." || name == "..") {
                                val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "bin"
                                name = "attachment.$extension"
                            }
                            directory.mkdirs()
                            val outputFile = File(directory, "$index-$name")
                            destination = outputFile
                            var size = 0L
                            app.contentResolver.openInputStream(uri)?.use { input ->
                                outputFile.outputStream().use { output ->
                                    val buffer = ByteArray(32 * 1024)
                                    while (true) {
                                        if (Thread.currentThread().isInterrupted || SystemClock.elapsedRealtime() > deadline) throw IOException()
                                        val count = input.read(buffer)
                                        if (count < 0) break
                                        size += count
                                        if (size > MAX_FILE || total + size > MAX_TOTAL) throw TooLarge()
                                        output.write(buffer, 0, count)
                                    }
                                }
                            } ?: throw IOException()
                            if (size == 0L) throw IOException()
                            total += size
                            files.add(mapOf("path" to outputFile.absolutePath, "name" to name, "mime" to mime, "size" to size))
                        } catch (failure: Exception) {
                            destination?.delete()
                            if (error != "too_large") error = if (failure is TooLarge) "too_large" else "unreadable"
                        }
                    }
                    if (text.isEmpty() && files.isEmpty() && error.isEmpty()) error = "unreadable"
                } catch (_: Exception) {
                    error = "unreadable"
                }
                val packet = mapOf("id" to id, "text" to text, "files" to files, "loading" to false, "error" to error)
                main.post {
                    if (finished.compareAndSet(false, true) && !disposed && pending.containsKey(id)) {
                        pending[id] = packet
                        notifyDart()
                    } else {
                        directory.deleteRecursively()
                    }
                }
            }
        } catch (_: Exception) {
            pending[id] = failure(id)
            notifyDart()
            return
        }
        main.postDelayed({
            if (finished.compareAndSet(false, true)) {
                future.cancel(true)
                if (!disposed && pending.containsKey(id)) {
                    pending[id] = failure(id)
                    notifyDart()
                }
            }
        }, 20_000)
    }

    private fun failure(id: String) = mapOf("id" to id, "text" to "", "files" to emptyList<Any>(), "loading" to false, "error" to "unreadable")
    private fun notifyDart() { if (!disposed) channel.invokeMethod("available", null) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pending" -> result.success(pending.values.toList())
            "ack" -> {
                val id = call.argument<String>("id")
                if (id != null && pending.remove(id) != null) {
                    try { io.execute { File(root, id).deleteRecursively() } } catch (_: Exception) { /* TTL cleanup */ }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        io.shutdownNow()
    }

    private class TooLarge : IOException()
    companion object {
        private const val MAX_FILE = 32L * 1024 * 1024
        private const val MAX_TOTAL = 64L * 1024 * 1024
    }
}
