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
import java.util.concurrent.Future
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Retains URI grants until a destination is chosen; imports files to disk only. */
internal class IncomingShareBridge(context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val app = context.applicationContext
    private val channel = MethodChannel(messenger, "vocechat/incoming_share")
    private val main = Handler(Looper.getMainLooper())
    private val io = ThreadPoolExecutor(1, 2, 30, TimeUnit.SECONDS, ArrayBlockingQueue(4))
    private val root = File(app.cacheDir, "incoming-shares")
    private val pending = linkedMapOf<String, Map<String, Any>>()
    private val requests = linkedMapOf<String, Request>()
    private var disposed = false
    private data class Entry(val uri: Uri, val name: String, val mime: String, val size: Long) {
        fun metadata() = mapOf("path" to "", "name" to name, "mime" to mime, "size" to size)
    }
    private class Request(val id: String, val intent: Intent) {
        val cancelled = AtomicBoolean(false)
        var future: Future<*>? = null
        var cancelWork: (() -> Unit)? = null
        var text = ""
        var entries = emptyList<Entry>()
        var preparedMode: String? = null
    }
    init {
        channel.setMethodCallHandler(this)
        io.execute {
            root.mkdirs()
            root.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > TimeUnit.DAYS.toMillis(1) }
                ?.forEach { it.deleteRecursively() }
        }
    }
    private fun metadata(request: Request, error: String = "", loading: Boolean = false): Map<String, Any> =
        mapOf("id" to request.id, "text" to request.text, "files" to request.entries.map { it.metadata() },
            "prepared" to false, "loading" to loading, "error" to error)

    fun receive(intent: Intent?) {
        if (disposed || intent?.action !in listOf(Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE) || pending.size >= 4) return
        val request = Request(UUID.randomUUID().toString(), Intent(intent))
        requests[request.id] = request
        pending[request.id] = metadata(request, loading = true)
        notifyDart()
        work(request, 20_000, null) { deadline ->
            request.text = request.intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty().take(1_000_000)
            val uris = mutableListOf<Uri>()
            if (request.intent.action == Intent.ACTION_SEND_MULTIPLE) {
                uris.addAll(IntentCompat.getParcelableArrayListExtra(request.intent, Intent.EXTRA_STREAM, Uri::class.java).orEmpty())
            } else {
                IntentCompat.getParcelableExtra(request.intent, Intent.EXTRA_STREAM, Uri::class.java)?.let { uris.add(it) }
            }
            request.intent.clipData?.let { clip ->
                for (i in 0 until minOf(clip.itemCount, 17)) clip.getItemAt(i).uri?.let { uris.add(it) }
            }
            val distinct = uris.distinct()
            if (distinct.size > 16) throw TooMany()
            request.entries = distinct.map { uri ->
                checkActive(request, deadline)
                if (uri.scheme != "content" || uri.authority?.startsWith(app.packageName) == true) throw IOException()
                val mime = app.contentResolver.getType(uri).orEmpty()
                var name = ""
                var size = 0L
                app.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val n = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        val s = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (n >= 0) name = cursor.getString(n).orEmpty()
                        if (s >= 0 && !cursor.isNull(s)) size = cursor.getLong(s).coerceAtLeast(0)
                    }
                }
                name = name.substringAfterLast('/').substringAfterLast('\\').replace(Regex("[\\p{Cntrl}]"), "_").take(160)
                if (name.isBlank() || name == "." || name == "..") name = "attachment.${MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "bin"}"
                Entry(uri, name, mime, size)
            }
            if (request.text.isEmpty() && request.entries.isEmpty()) throw IOException()
            metadata(request)
        }
    }
    private fun checkActive(request: Request, deadline: Long) {
        if (request.cancelled.get() || Thread.currentThread().isInterrupted || SystemClock.elapsedRealtime() > deadline) throw IOException()
    }
    private fun prepare(request: Request, mode: String, result: MethodChannel.Result) {
        if (pending[request.id]?.get("loading") == true) { result.error("busy", "Share is still loading", null); return }
        if (request.preparedMode == mode) { result.success(pending[request.id]); return }
        if (pending[request.id]?.get("error") in listOf("too_many", "unreadable")) { result.success(pending[request.id]); return }
        pending[request.id] = metadata(request, loading = true)
        notifyDart()
        work(request, 15 * 60_000L, result) { deadline ->
            val directory = File(root, request.id)
            directory.deleteRecursively()
            val maxFile = MAX_TRANSFER
            val maxTotal = MAX_TRANSFER
            val files = mutableListOf<Map<String, Any>>()
            var total = 0L
            try {
                for ((index, entry) in request.entries.withIndex()) {
                    checkActive(request, deadline)
                    if (entry.size > maxFile || total + entry.size > maxTotal) throw TooLarge(mode)
                    val parent = File(directory, index.toString())
                    if (!parent.mkdirs() && !parent.isDirectory) throw IOException()
                    val outputFile = File(parent, entry.name)
                    var size = 0L
                    app.contentResolver.openInputStream(entry.uri)?.use { input ->
                        outputFile.outputStream().use { output ->
                            val buffer = ByteArray(256 * 1024)
                            while (true) {
                                checkActive(request, deadline)
                                val count = input.read(buffer)
                                if (count < 0) break
                                size += count
                                if (size > maxFile || total + size > maxTotal) throw TooLarge(mode)
                                output.write(buffer, 0, count)
                            }
                        }
                    } ?: throw IOException()
                    if (size == 0L) throw IOException()
                    total += size
                    files.add(mapOf("path" to outputFile.absolutePath, "name" to entry.name, "mime" to entry.mime, "size" to size))
                }
                request.preparedMode = mode
                mapOf("id" to request.id, "text" to request.text, "files" to files, "prepared" to true, "loading" to false, "error" to "")
            } catch (error: Exception) {
                directory.deleteRecursively()
                request.preparedMode = null
                throw error
            }
        }
    }
    private fun work(request: Request, timeout: Long, result: MethodChannel.Result?, action: (Long) -> Map<String, Any>) {
        val finished = AtomicBoolean(false)
        val deadline = SystemClock.elapsedRealtime() + timeout
        var timeoutTask: Runnable? = null
        val future = try {
            io.submit {
                val packet = try { action(deadline) } catch (error: Exception) {
                    metadata(request, when (error) {
                        is TooMany -> "too_many"
                        is TooLarge -> "too_large"
                        else -> "unreadable"
                    })
                }
                main.post {
                    if (finished.compareAndSet(false, true)) {
                        timeoutTask?.let { main.removeCallbacks(it) }
                        request.cancelWork = null
                        if (!disposed && requests[request.id] === request && !request.cancelled.get()) {
                            pending[request.id] = packet
                            notifyDart()
                            result?.success(packet)
                        } else result?.error("cancelled", "Share was cancelled", null)
                    }
                    if (request.cancelled.get() && !disposed) io.execute { File(root, request.id).deleteRecursively() }
                }
            }
        } catch (_: Exception) {
            pending[request.id] = metadata(request, "unreadable")
            notifyDart()
            result?.success(pending[request.id])
            return
        }
        request.future = future
        timeoutTask = Runnable {
            if (finished.compareAndSet(false, true)) {
                request.cancelWork = null
                future.cancel(true)
                if (!disposed && requests[request.id] === request) {
                    pending[request.id] = metadata(request, "unreadable")
                    notifyDart()
                    result?.success(pending[request.id])
                } else result?.error("cancelled", "Share was cancelled", null)
            }
        }
        request.cancelWork = {
            if (finished.compareAndSet(false, true)) {
                future.cancel(true)
                timeoutTask?.let { main.removeCallbacks(it) }
                result?.error("cancelled", "Share was cancelled", null)
            }
        }
        main.postDelayed(timeoutTask!!, timeout)
    }
    private fun notifyDart() { if (!disposed) channel.invokeMethod("available", null) }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pending" -> result.success(pending.values.toList())
            "prepare" -> {
                val request = requests[call.argument<String>("id")]
                val mode = call.argument<String>("mode")
                if (request == null || mode !in listOf("chat", "transfer")) result.error("invalid", "Unknown share destination", null)
                else prepare(request, mode!!, result)
            }
            "ack" -> {
                val request = requests.remove(call.argument<String>("id"))
                if (request != null) {
                    request.cancelled.set(true)
                    request.cancelWork?.invoke()
                    request.future?.cancel(true)
                    pending.remove(request.id)
                    try { io.execute { File(root, request.id).deleteRecursively() } } catch (_: Exception) { /* TTL cleanup */ }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
    fun dispose() {
        disposed = true
        for (request in requests.values) { request.cancelled.set(true); request.cancelWork?.invoke(); request.future?.cancel(true) }
        channel.setMethodCallHandler(null)
        io.shutdownNow()
    }
    private class TooLarge(val mode: String) : IOException()
    private class TooMany : IOException()
    companion object {
        private const val MAX_TRANSFER = 1L shl 40
    }
}
