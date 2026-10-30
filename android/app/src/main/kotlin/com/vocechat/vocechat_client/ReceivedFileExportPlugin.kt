package com.vocechat.vocechat_client

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Moves a received file through SAF, retaining its source until verified. */
internal class ReceivedFileExporter(
    private val app: Context,
    private val storage: ReceivedFileStorage = ReceivedFileStorage(app),
    private val launch: (Intent) -> Unit,
) {
    private class Request(val source: ReceivedFileStorage.Source, val reply: MethodChannel.Result) {
        val cancelled = AtomicBoolean(false)
    }
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var pending: Request? = null

    fun save(path: String?, reply: MethodChannel.Result, scope: String? = null, uri: String? = null) {
        if (pending != null) { reply.error("busy", "A save is in progress", null); return }
        val source = try {
            storage.source(path, scope, uri)
        } catch (_: Exception) { reply.error("file", "Received file is unavailable", null); return }
        val request = Request(source, reply)
        pending = request
        try {
            launch(Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                .setType(MimeTypeMap.getSingleton().getMimeTypeFromExtension(source.name.substringAfterLast('.', "").lowercase(Locale.ROOT)) ?: "application/octet-stream")
                .putExtra(Intent.EXTRA_TITLE, source.name))
        } catch (_: Exception) {
            pending = null
            reply.error("picker", "Cannot open save dialog", null)
        }
    }

    fun onResult(resultCode: Int, data: Intent?): Boolean {
        val request = pending ?: return false
        if (resultCode != Activity.RESULT_OK) {
            pending = null
            request.reply.success(false)
            return true
        }
        val uri = data?.data
        if (uri == null || uri.scheme != "content" || uri.authority?.startsWith(app.packageName) == true) {
            pending = null
            request.reply.error("destination", "Invalid save destination", null)
            return true
        }
        if (storage.sameSource(request.source, uri)) {
            pending = null
            request.reply.error("destination", "Choose a different file", null)
            return true
        }
        io.execute {
            val moved = try { storage.move(request.source, uri, request.cancelled); true } catch (_: Exception) {
                storage.removeDestination(uri)
                false
            }
            main.post {
                if (pending === request) {
                    pending = null
                    if (moved) request.reply.success(true)
                    else request.reply.error("save", "Could not move received file", null)
                }
            }
        }
        return true
    }

    fun cancelPending() {
        pending?.let {
            it.cancelled.set(true)
            it.reply.error("cancelled", "Save was cancelled", null)
        }
        pending = null
    }

    fun dispose() { cancelPending(); io.shutdownNow() }
}

class ReceivedFileExportPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private var binding: ActivityPluginBinding? = null
    private var channel: MethodChannel? = null
    private var exporter: ReceivedFileExporter? = null
    private var storage: ReceivedFileStorage? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private data class FolderChoice(val scope: String, val kind: String, val result: MethodChannel.Result)
    private var folderChoice: FolderChoice? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        storage = ReceivedFileStorage(binding.applicationContext)
        exporter = ReceivedFileExporter(binding.applicationContext, storage!!) { intent ->
            val activity = this.binding?.activity ?: throw IllegalStateException("No activity")
            activity.startActivityForResult(intent, REQUEST)
        }
        channel = MethodChannel(binding.binaryMessenger, "chat.voce/received_file_export").also {
            it.setMethodCallHandler { call, result ->
                try {
                    val scope = call.argument<String>("scope")
                    when (call.method) {
                        "save" -> if (folderChoice != null) result.error("busy", "Folder dialog is open", null)
                            else exporter!!.save(call.argument<String>("path"), result, scope, call.argument<String>("uri"))
                        "locations" -> async(result) { it.snapshot(scope!!) }
                        "store" -> async(result) { it.store(call.argument<String>("path")!!, scope!!) }
                        "resetLocation" -> async(result) {
                            it.setLocation(scope!!, call.argument<String>("kind")!!, null)
                            it.snapshot(scope)
                        }
                        "chooseLocation" -> {
                            if (folderChoice != null) { result.error("busy", "Folder dialog is open", null); return@setMethodCallHandler }
                            val kind = call.argument<String>("kind")!!
                            val initial = storage!!.location(scope!!, kind)
                            val activity = this.binding?.activity ?: throw IllegalStateException()
                            folderChoice = FolderChoice(scope, kind, result)
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                            if (android.os.Build.VERSION.SDK_INT >= 26 && initial != null)
                                intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initial)
                            try { activity.startActivityForResult(intent, FOLDER_REQUEST) }
                            catch (error: Exception) { folderChoice = null; throw error }
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) { result.error("storage", "Storage operation failed", null) }
            }
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        exporter?.dispose()
        exporter = null
        channel = null
        storage = null
        io.shutdownNow()
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addActivityResultListener(this)
    }
    override fun onDetachedFromActivityForConfigChanges() { detach() }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { onAttachedToActivity(binding) }
    override fun onDetachedFromActivity() {
        detach(); exporter?.cancelPending()
        folderChoice?.result?.success(null)
        folderChoice = null
    }
    private fun detach() {
        binding?.removeActivityResultListener(this)
        binding = null
    }
    private fun async(result: MethodChannel.Result, action: (ReceivedFileStorage) -> Any?) {
        val owner = storage ?: throw IllegalStateException()
        io.execute {
            try {
                val value = action(owner)
                main.post { if (storage === owner) result.success(value) }
            } catch (_: Exception) {
                main.post { if (storage === owner) result.error("storage", "Storage operation failed", null) }
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == FOLDER_REQUEST) {
            val choice = folderChoice ?: return false
            folderChoice = null
            if (resultCode != Activity.RESULT_OK || data?.data == null) choice.result.success(null)
            else async(choice.result) {
                it.setLocation(choice.scope, choice.kind, data.data, data.flags)
                it.snapshot(choice.scope)
            }
            return true
        }
        return requestCode == REQUEST && exporter?.onResult(resultCode, data) == true
    }
    companion object {
        private const val REQUEST = 0x56F1
        private const val FOLDER_REQUEST = 0x56F2
    }
}
