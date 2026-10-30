package com.vocechat.vocechat_client

import android.app.Application
import android.app.Activity
import android.content.ContentProvider
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowContentResolver
import org.json.JSONArray
import java.io.File
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import io.flutter.plugin.common.MethodChannel

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], shadows = [FolderDocumentsShadow::class])
class ReceivedFileStorageTest {
    private val app: Application get() = RuntimeEnvironment.getApplication()
    private val scope = "a".repeat(64)
    private val otherScope = "b".repeat(64)
    private val access = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    private val images = Uri.parse("content://folders.test/tree/images")
    private val files = Uri.parse("content://folders.test/tree/files")
    private lateinit var storage: ReceivedFileStorage

    @Before fun setup() {
        val provider = FolderProvider()
        provider.attachInfo(app, ProviderInfo().apply { authority = "folders.test"; exported = true; grantUriPermissions = true })
        ShadowContentResolver.registerProviderInternal("folders.test", provider)
        FolderDocumentsShadow.provider = provider
        storage = ReceivedFileStorage(app)
    }
    private fun source(name: String, scope: String = this.scope): File =
        File(app.getDir("flutter", Context.MODE_PRIVATE), "local_transfers/$scope/$name").apply {
            parentFile!!.mkdirs(); writeBytes(byteArrayOf(4, 5, 6, 7))
        }
    private fun configure() {
        storage.setLocation(scope, "images", images, access)
        storage.setLocation(scope, "files", files, access)
    }

    @Test fun imagesAndFilesUseSeparatePersistentFoldersWithoutMovingExistingFiles() {
        val old = source("old.bin")
        configure()
        assertTrue(old.exists())
        val image = source("photo.HEIC")
        val file = source("archive.zip")
        val i = storage.store(image.path, scope)!!
        val f = storage.store(file.path, scope)!!
        assertTrue(DocumentsContract.getDocumentId(Uri.parse(i["uri"] as String)).startsWith("images/"))
        assertTrue(DocumentsContract.getDocumentId(Uri.parse(f["uri"] as String)).startsWith("files/"))
        assertFalse(image.exists()); assertFalse(file.exists()); assertTrue(old.exists())
        val reopened = ReceivedFileStorage(app).snapshot(scope)
        assertEquals(2, (reopened["received"] as List<*>).size)
        assertEquals(files, ReceivedFileStorage(app).location(scope, "files"))
        assertNull(storage.location(otherScope, "files"))
        val isolated = source("isolated.bin", otherScope)
        assertNull(storage.store(isolated.path, otherScope))
        assertTrue(isolated.exists())
    }

    @Test fun duplicateNamesPreserveBothAndEmptyFilesAreSupported() {
        configure()
        val first = storage.store(source("same.txt").path, scope)!!
        val second = storage.store(source("same.txt").path, scope)!!
        assertEquals("same.txt", first["name"])
        assertEquals("same (1).txt", second["name"])
        assertNotEquals(first["uri"], second["uri"])
        val empty = source("empty.bin").apply { writeBytes(byteArrayOf()) }
        assertEquals(0L, storage.store(empty.path, scope)!!["size"])
        assertFalse(empty.exists())
    }

    @Test fun unavailableFolderRetainsOriginalAndCreatesNoReceivedRecord() {
        configure()
        val original = source("keep.bin")
        FolderDocumentsShadow.provider.failWrite = true
        assertThrows(IOException::class.java) { storage.store(original.path, scope) }
        assertArrayEquals(byteArrayOf(4, 5, 6, 7), original.readBytes())
        assertTrue((storage.snapshot(scope)["received"] as List<*>).isEmpty())
        assertTrue(FolderDocumentsShadow.provider.entries.isEmpty())
    }

    @Test fun managedFileCanMoveAgainAndCannotOverwriteItself() {
        configure()
        val stored = storage.store(source("move.bin").path, scope)!!
        val original = Uri.parse(stored["uri"] as String)
        val source = storage.source(null, scope, original.toString())
        assertThrows(IllegalArgumentException::class.java) { storage.move(source, original, AtomicBoolean(false)) }
        assertTrue(FolderDocumentsShadow.provider.entries.containsKey(DocumentsContract.getDocumentId(original)))
        val exporter = ReceivedFileExporter(app, storage) { }
        var error: String? = null
        val reply = object : MethodChannel.Result {
            override fun success(value: Any?) { fail("Saving over source must fail") }
            override fun error(code: String, message: String?, details: Any?) { error = code }
            override fun notImplemented() { fail("Missing method") }
        }
        exporter.save(null, reply, scope, original.toString())
        exporter.onResult(Activity.RESULT_OK, Intent().setData(original))
        assertEquals("destination", error)
        assertTrue(FolderDocumentsShadow.provider.entries.containsKey(DocumentsContract.getDocumentId(original)))
        exporter.dispose()
        val parent = DocumentsContract.buildDocumentUriUsingTree(files, "files")
        val target = DocumentsContract.createDocument(app.contentResolver, parent, "application/octet-stream", "moved.bin")!!
        storage.move(source, target, AtomicBoolean(false))
        assertFalse(FolderDocumentsShadow.provider.entries.containsKey(DocumentsContract.getDocumentId(original)))
        assertArrayEquals(byteArrayOf(4, 5, 6, 7), app.contentResolver.openInputStream(target)!!.use { it.readBytes() })
        assertTrue((storage.snapshot(scope)["received"] as List<*>).isEmpty())
    }

    @Test fun resetDoesNotMoveStoredFilesAndUserDeletedDocumentsLeaveHistory() {
        configure()
        val stored = storage.store(source("existing.jpg").path, scope)!!
        storage.setLocation(scope, "images", null)
        val newImage = source("new.jpg")
        assertNull(storage.store(newImage.path, scope))
        assertTrue(newImage.exists())
        assertEquals(1, (storage.snapshot(scope)["received"] as List<*>).size)
        DocumentsContract.deleteDocument(app.contentResolver, Uri.parse(stored["uri"] as String))
        assertTrue((storage.snapshot(scope)["received"] as List<*>).isEmpty())
    }

    @Test fun rejectsUnmanagedUrisAndWrongAccountSources() {
        assertThrows(IOException::class.java) { storage.source(null, scope, "content://folders.test/document/unknown") }
        assertThrows(IllegalArgumentException::class.java) { storage.source(source("wrong.bin").path, otherScope) }
        assertThrows(IllegalArgumentException::class.java) { storage.location("../invalid", "files") }
    }

    @Test fun commonImagesAreSeparatedFromVideosAndDocuments() {
        for (name in listOf("photo.JPG", "photo.heic", "photo.avif", "animated.gif", "photo.webp"))
            assertEquals("images", ReceivedFileStorage.category(name))
        for (name in listOf("movie.mp4", "app.apk", "file.pdf", "no-extension"))
            assertEquals("files", ReceivedFileStorage.category(name))
    }

    @Test fun interruptedCommitRecoversOnlyMatchingOriginals() {
        configure()
        for (changed in listOf(false, true)) {
            val name = "journal-$changed.bin"
            val saved = storage.store(source(name).path, scope)!!
            val original = source(name)
            if (changed) original.writeText("new contents must survive")
            val prefs = app.getSharedPreferences("received_file_locations", Context.MODE_PRIVATE)
            val records = JSONArray(prefs.getString("$scope.records", "[]"))
            for (i in 0 until records.length()) {
                val record = records.getJSONObject(i)
                if (record.getString("uri") == saved["uri"]) record.put("pendingPath", original.path)
            }
            prefs.edit().putString("$scope.records", records.toString()).commit()
            ReceivedFileStorage(app).snapshot(scope)
            assertEquals(changed, original.exists())
            if (changed) assertEquals("new contents must survive", original.readText())
        }
    }
}

class FolderProvider : ContentProvider() {
    data class Entry(val file: File, val name: String)
    val entries = linkedMapOf<String, Entry>()
    var failWrite = false
    private var sequence = 0
    override fun onCreate() = true
    fun create(parent: Uri, name: String): Uri {
        val id = "${DocumentsContract.getDocumentId(parent)}/${++sequence}"
        val file = File(context!!.cacheDir, "doc-$sequence").apply { writeBytes(byteArrayOf()) }
        entries[id] = Entry(file, name)
        return DocumentsContract.buildDocumentUriUsingTree(parent, id)
    }
    fun remove(uri: Uri): Boolean = entries.remove(DocumentsContract.getDocumentId(uri))?.file?.delete() ?: false
    override fun getType(uri: Uri) = "application/octet-stream"
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, order: String?): Cursor {
        val columns = projection ?: arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        val cursor = MatrixCursor(columns)
        val id = DocumentsContract.getDocumentId(uri)
        fun row(name: String, file: File?) = columns.map<String, Any?> {
            when (it) {
                DocumentsContract.Document.COLUMN_DISPLAY_NAME -> name
                DocumentsContract.Document.COLUMN_SIZE -> file?.length() ?: 0L
                DocumentsContract.Document.COLUMN_LAST_MODIFIED -> file?.lastModified() ?: 0L
                else -> null
            }
        }.toTypedArray()
        if (uri.lastPathSegment == "children") entries.filterKeys { it.startsWith("$id/") }.values.forEach { cursor.addRow(row(it.name, it.file)) }
        else if (entries.containsKey(id)) entries[id]!!.let { cursor.addRow(row(it.name, it.file)) }
        else if (!id.contains('/')) cursor.addRow(row(id, null))
        return cursor
    }
    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (failWrite && mode != "r") throw IOException("folder unavailable")
        val file = entries[DocumentsContract.getDocumentId(uri)]!!.file
        return ParcelFileDescriptor.open(file, if (mode == "r") ParcelFileDescriptor.MODE_READ_ONLY else
            ParcelFileDescriptor.MODE_WRITE_ONLY or ParcelFileDescriptor.MODE_TRUNCATE)
    }
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, args: Array<out String>?) = if (remove(uri)) 1 else 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = 0
}

@Implements(DocumentsContract::class)
class FolderDocumentsShadow {
    companion object {
        lateinit var provider: FolderProvider
        @Implementation @JvmStatic fun createDocument(resolver: ContentResolver, parent: Uri, mime: String, name: String): Uri = provider.create(parent, name)
        @Implementation @JvmStatic fun deleteDocument(resolver: ContentResolver, uri: Uri): Boolean = provider.remove(uri)
    }
}
