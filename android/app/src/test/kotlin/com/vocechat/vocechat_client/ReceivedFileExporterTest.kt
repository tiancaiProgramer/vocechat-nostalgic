package com.vocechat.vocechat_client

import android.app.Activity
import android.app.Application
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.net.Uri
import android.os.Looper
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowContentResolver
import java.io.File
import java.io.FileNotFoundException
import java.io.RandomAccessFile
import java.security.MessageDigest

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class ReceivedFileExporterTest {
    private val app: Application get() = RuntimeEnvironment.getApplication()
    private val uri = Uri.parse("content://export.test/document/one")
    private fun source(name: String = "received.bin"): File =
        File(app.getDir("flutter", Context.MODE_PRIVATE), "local_transfers/account/$name").apply {
            parentFile!!.mkdirs()
            writeBytes(byteArrayOf(1, 2, 3, 4, 5))
        }
    private class Reply : MethodChannel.Result {
        var count = 0
        var value: Any? = null
        var error: String? = null
        override fun success(result: Any?) { count++; value = result }
        override fun error(code: String, message: String?, details: Any?) { count++; error = code }
        override fun notImplemented() { error("missing", null, null) }
    }
    private fun await(reply: Reply) {
        val deadline = System.nanoTime() + 20_000_000_000L
        while (reply.count == 0 && System.nanoTime() < deadline) {
            shadowOf(Looper.getMainLooper()).idle()
            Thread.sleep(5)
        }
        assertEquals("one final reply", 1, reply.count)
    }
    private fun provider(corrupt: Boolean = false, fail: Boolean = false): File {
        val output = File(app.cacheDir, "export-target.bin").apply { delete() }
        val broken = File(app.cacheDir, "corrupt-read.bin").apply { writeBytes(byteArrayOf(9)) }
        val provider = object : ContentProvider() {
            override fun onCreate() = true
            override fun getType(uri: Uri) = "application/octet-stream"
            override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, order: String?): Cursor? = null
            override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
                if (fail && mode != "r") throw FileNotFoundException("test write failure")
                return if (mode == "r") ParcelFileDescriptor.open(if (corrupt) broken else output, ParcelFileDescriptor.MODE_READ_ONLY)
                else ParcelFileDescriptor.open(output, ParcelFileDescriptor.MODE_CREATE or ParcelFileDescriptor.MODE_TRUNCATE or ParcelFileDescriptor.MODE_WRITE_ONLY)
            }
            override fun insert(uri: Uri, values: ContentValues?): Uri? = null
            override fun delete(uri: Uri, selection: String?, args: Array<out String>?): Int = if (output.delete()) 1 else 0
            override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = 0
        }
        provider.attachInfo(app, ProviderInfo().apply { authority = "export.test"; exported = true })
        ShadowContentResolver.registerProviderInternal("export.test", provider)
        return output
    }
    private fun hash(file: File): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(256 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest()
    }

    @Test fun pickerFirstThenMoves80MiBOnlyAfterDestinationIsVerified() {
        val source = source()
        RandomAccessFile(source, "rw").use { it.setLength(80L * 1024 * 1024); it.seek(it.length() - 3); it.write(byteArrayOf(7, 8, 9)) }
        val expected = hash(source)
        val output = provider()
        var intent: Intent? = null
        val exporter = ReceivedFileExporter(app) { intent = it }
        val reply = Reply()
        try {
            exporter.save(source.path, reply)
            assertEquals(Intent.ACTION_CREATE_DOCUMENT, intent!!.action)
            assertTrue(intent!!.hasCategory(Intent.CATEGORY_OPENABLE))
            assertEquals(source.name, intent!!.getStringExtra(Intent.EXTRA_TITLE))
            assertTrue(source.exists())
            assertFalse(output.exists())
            assertEquals(0, reply.count)
            assertTrue(exporter.onResult(Activity.RESULT_OK, Intent().setData(uri)))
            await(reply)
            assertNull(reply.error)
            assertEquals(true, reply.value)
            assertFalse(source.exists())
            assertEquals(80L * 1024 * 1024, output.length())
            assertArrayEquals(expected, hash(output))
        } finally { exporter.dispose() }
    }

    @Test fun cancelLeavesOriginalAndDoesNotWriteOrShowSuccess() {
        val source = source()
        val output = provider()
        val exporter = ReceivedFileExporter(app) { }
        val reply = Reply()
        try {
            exporter.save(source.path, reply)
            exporter.onResult(Activity.RESULT_CANCELED, null)
            assertEquals(false, reply.value)
            assertNull(reply.error)
            assertTrue(source.exists())
            assertFalse(output.exists())
        } finally { exporter.dispose() }
    }

    @Test fun corruptDestinationPreservesOriginalAndRemovesFailedOutput() {
        val source = source()
        val expected = source.readBytes()
        val output = provider(corrupt = true)
        val exporter = ReceivedFileExporter(app) { }
        val reply = Reply()
        try {
            exporter.save(source.path, reply)
            exporter.onResult(Activity.RESULT_OK, Intent().setData(uri))
            await(reply)
            assertEquals("save", reply.error)
            assertArrayEquals(expected, source.readBytes())
            assertFalse(output.exists())
        } finally { exporter.dispose() }
    }

    @Test fun writeFailurePreservesOriginal() {
        val source = source()
        val output = provider(fail = true)
        val exporter = ReceivedFileExporter(app) { }
        val reply = Reply()
        try {
            exporter.save(source.path, reply)
            exporter.onResult(Activity.RESULT_OK, Intent().setData(uri))
            await(reply)
            assertEquals("save", reply.error)
            assertTrue(source.exists())
            assertFalse(output.exists())
        } finally { exporter.dispose() }
    }

    @Test fun rejectsNonReceivedPathsAndOwnProviderWithoutReadingSource() {
        var launches = 0
        val exporter = ReceivedFileExporter(app) { launches++ }
        try {
            val other = File(app.filesDir, "private.txt").apply { writeText("private") }
            val outside = Reply()
            exporter.save(other.path, outside)
            assertEquals("file", outside.error)
            assertEquals(0, launches)
            val valid = source()
            val own = Reply()
            exporter.save(valid.path, own)
            exporter.onResult(Activity.RESULT_OK, Intent().setData(Uri.parse("content://${app.packageName}.fileProvider/received")))
            assertEquals("destination", own.error)
            assertTrue(valid.exists())
            assertEquals("private", other.readText())
        } finally { exporter.dispose() }
    }
}
