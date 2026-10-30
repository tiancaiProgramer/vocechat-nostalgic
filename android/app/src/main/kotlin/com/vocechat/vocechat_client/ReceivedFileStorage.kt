package com.vocechat.vocechat_client

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

internal class ReceivedFileStorage(private val app: Context) {
    private val prefs = app.getSharedPreferences("received_file_locations", Context.MODE_PRIVATE)
    private val resolver get() = app.contentResolver
    private val root get() = File(app.getDir("flutter", Context.MODE_PRIVATE), "local_transfers").canonicalFile

    internal class Source(val name: String, val size: Long, val open: () -> InputStream,
                          val remove: () -> Boolean, val unchanged: () -> Boolean,
                          val uri: Uri? = null)

    fun source(path: String?, scope: String? = null, uri: String? = null): Source {
        if (uri != null) {
            val key = scope(scope)
            val record = records(key).firstOrNull { it.getString("uri") == uri } ?: throw IOException()
            val source = Uri.parse(uri)
            fun metadata(): Pair<Long, Long> = resolver.query(source,
                arrayOf(DocumentsContract.Document.COLUMN_SIZE, DocumentsContract.Document.COLUMN_LAST_MODIFIED), null, null, null)?.use {
                if (!it.moveToFirst()) throw IOException()
                it.getLong(0) to it.getLong(1)
            } ?: throw IOException()
            val original = metadata()
            return Source(record.getString("name"), record.getLong("size"),
                { resolver.openInputStream(source) ?: throw IOException() },
                {
                    val deleted = DocumentsContract.deleteDocument(resolver, source)
                    if (deleted) try { forget(key, uri) } catch (_: Exception) { }
                    deleted
                }, { metadata() == original }, source)
        }
        val file = File(path ?: "").canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.isFile && file.canRead())
        if (scope != null) require(file.parentFile?.canonicalFile == File(root, scope(scope)).canonicalFile)
        val length = file.length()
        val modified = file.lastModified()
        return Source(file.name, length, { file.inputStream() }, { file.delete() },
            { file.length() == length && file.lastModified() == modified })
    }

    /** Copy to a fresh document, read it back, then unlink the source. */
    fun move(source: Source, destination: Uri, cancelled: AtomicBoolean,
             beforeDelete: (String) -> Unit = {}) {
        require(destination.scheme == "content" && destination.authority?.startsWith(app.packageName) != true)
        require(!sameSource(source, destination))
        val buffer = ByteArray(256 * 1024)
        val hash = MessageDigest.getInstance("SHA-256")
        var written = 0L
        fun active() { if (cancelled.get() || Thread.currentThread().isInterrupted) throw IOException() }
        resolver.openOutputStream(destination, "w")?.use { output ->
            source.open().use { input ->
                while (true) {
                    active()
                    val count = input.read(buffer)
                    if (count < 0) break
                    output.write(buffer, 0, count)
                    hash.update(buffer, 0, count)
                    written += count
                }
            }
            output.flush()
        } ?: throw IOException()
        val expected = hash.digest()
        var verified = 0L
        val check = MessageDigest.getInstance("SHA-256")
        resolver.openInputStream(destination)?.use { input ->
            while (true) {
                active()
                val count = input.read(buffer)
                if (count < 0) break
                check.update(buffer, 0, count)
                verified += count
            }
        } ?: throw IOException()
        active()
        if (written != source.size || verified != source.size ||
            !MessageDigest.isEqual(expected, check.digest()) || !source.unchanged()) throw IOException()
        beforeDelete(expected.joinToString("") { "%02x".format(it) })
        if (!source.remove()) throw IOException()
    }

    fun removeDestination(uri: Uri) {
        try { if (DocumentsContract.isDocumentUri(app, uri) && DocumentsContract.deleteDocument(resolver, uri)) return } catch (_: Exception) { }
        try { resolver.delete(uri, null, null) } catch (_: Exception) { }
    }

    fun sameSource(source: Source, destination: Uri): Boolean {
        val original = source.uri ?: return false
        if (original == destination) return true
        return try { original.authority == destination.authority &&
            DocumentsContract.getDocumentId(original) == DocumentsContract.getDocumentId(destination)
        } catch (_: Exception) { false }
    }

    private fun scope(value: String?): String {
        require(value != null && value.matches(Regex("[a-f0-9]{64}")))
        return value
    }
    private fun kind(value: String): String { require(value == "images" || value == "files"); return value }
    private fun records(scope: String): List<JSONObject> {
        val array = JSONArray(prefs.getString("$scope.records", "[]"))
        return (0 until array.length()).map { array.getJSONObject(it) }
    }
    private fun writeRecords(scope: String, records: List<JSONObject>) {
        if (!prefs.edit().putString("$scope.records", JSONArray(records).toString()).commit()) throw IOException()
    }
    @Synchronized private fun forget(scope: String, uri: String) = writeRecords(scope, records(scope).filter { it.getString("uri") != uri })

    fun location(scope: String, kind: String): Uri? =
        prefs.getString("${scope(scope)}.${kind(kind)}", null)?.let(Uri::parse)

    fun setLocation(scope: String, kind: String, uri: Uri?, flags: Int = 0) {
        val key = "${scope(scope)}.${kind(kind)}"
        if (uri == null) {
            if (!prefs.edit().remove(key).commit()) throw IOException()
            return
        }
        require(uri.scheme == "content" && DocumentsContract.isTreeUri(uri))
        val access = flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        require(access == (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
        resolver.takePersistableUriPermission(uri, access)
        if (!prefs.edit().putString(key, uri.toString()).commit()) throw IOException()
    }

    fun label(tree: Uri): String {
        val id = DocumentsContract.getTreeDocumentId(tree)
        if (tree.authority == "com.android.externalstorage.documents") {
            return id.replaceFirst("primary:", "")
        }
        val document = DocumentsContract.buildDocumentUriUsingTree(tree, id)
        return try {
            resolver.query(document, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0) else id
            } ?: id
        } catch (_: Exception) { id }
    }

    @Synchronized fun snapshot(scope: String): Map<String, Any?> {
        val key = scope(scope)
        val saved = records(key).filter { record ->
            try {
                val uri = Uri.parse(record.getString("uri"))
                val exists = resolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { it.moveToFirst() } ?: false
                if (exists && record.has("pendingPath")) recover(record)
                exists
            } catch (_: SecurityException) { true } catch (_: Exception) { true }
        }
        writeRecords(key, saved)
        fun folder(kind: String): Map<String, String>? = location(key, kind)?.let { mapOf("uri" to it.toString(), "label" to label(it)) }
        return mapOf("images" to folder("images"), "files" to folder("files"),
            "received" to saved.map { record -> mapOf("uri" to record.getString("uri"), "name" to record.getString("name"),
                "size" to record.getLong("size"), "location" to record.getString("location")) })
    }

    private fun recover(record: JSONObject) {
        val file = File(record.getString("pendingPath")).canonicalFile
        require(file.path.startsWith(root.path + File.separator))
        if (file.exists()) {
            fun digest(input: InputStream): String = input.use {
                val hash = MessageDigest.getInstance("SHA-256")
                val buffer = ByteArray(256 * 1024)
                while (true) { val count = it.read(buffer); if (count < 0) break; hash.update(buffer, 0, count) }
                hash.digest().joinToString("") { byte -> "%02x".format(byte) }
            }
            val expected = record.getString("hash")
            if (digest(file.inputStream()) != expected ||
                digest(resolver.openInputStream(Uri.parse(record.getString("uri"))) ?: throw IOException()) != expected || !file.delete()) throw IOException()
        }
        record.remove("pendingPath")
    }

    @Synchronized fun store(path: String, scope: String): Map<String, Any?>? {
        val key = scope(scope)
        val source = source(path, key)
        val tree = location(key, category(source.name)) ?: return null
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val names = hashSetOf<String>()
        resolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            while (it.moveToNext()) names.add(it.getString(0))
        } ?: throw IOException()
        val name = uniqueName(source.name, names)
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(name.substringAfterLast('.', "").lowercase(Locale.ROOT)) ?: "application/octet-stream"
        val destination = DocumentsContract.createDocument(resolver, parent, mime, name) ?: throw IOException()
        val record = JSONObject().put("uri", destination.toString()).put("tree", tree.toString())
            .put("name", name).put("size", source.size).put("location", label(tree))
        try {
            move(source, destination, AtomicBoolean(false)) { hash ->
                record.put("pendingPath", path).put("hash", hash)
                writeRecords(key, listOf(record) + records(key))
            }
        } catch (error: Exception) {
            try { forget(key, destination.toString()) } finally { removeDestination(destination) }
            throw error
        }
        // The pending-path journal is safe to clear on the next snapshot too.
        record.remove("pendingPath")
        try { writeRecords(key, records(key).map { if (it.getString("uri") == destination.toString()) record else it }) } catch (_: Exception) { }
        return mapOf("uri" to destination.toString(), "name" to name, "size" to source.size, "location" to label(tree))
    }

    companion object {
        fun category(name: String): String = if (name.substringAfterLast('.', "").lowercase(Locale.ROOT) in
            setOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif", "avif", "tif", "tiff", "dng", "svg")) "images" else "files"
        fun uniqueName(name: String, existing: Set<String>): String {
            if (name !in existing) return name
            val dot = name.lastIndexOf('.').takeIf { it > 0 } ?: name.length
            val stem = name.substring(0, dot)
            val suffix = name.substring(dot)
            var n = 1
            while ("$stem ($n)$suffix" in existing) n++
            return "$stem ($n)$suffix"
        }
    }
}
