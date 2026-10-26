package com.vocechat.vocechat_client

import android.app.Application
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Intent
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowContentResolver
import java.io.File
import java.nio.ByteBuffer

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class IncomingShareBridgeTest {
    private val app: Application get() = RuntimeEnvironment.getApplication()

    @Test fun textAndUrlsWaitForExplicitSelectionAndDoNotLaunchOrSendAnything() {
        val messenger = FakeMessenger()
        val bridge = IncomingShareBridge(app, messenger)
        try {
            bridge.receive(Intent(Intent.ACTION_SEND).setType("text/plain")
                .putExtra(Intent.EXTRA_TEXT, "https://example.test/分享"))
            val packet = awaitPacket(messenger)
            assertEquals("https://example.test/分享", packet["text"])
            assertTrue((packet["files"] as List<*>).isEmpty())
            assertEquals("", packet["error"])
            assertNull(shadowOf(app).nextStartedActivity)
            messenger.invoke("ack", mapOf("id" to packet["id"]))
            assertTrue((messenger.invoke("pending", null) as List<*>).isEmpty())
        } finally { bridge.dispose() }
    }

    @Test fun rejectsFileSchemeAndOwnProviderInsteadOfReadingPrivatePaths() {
        for (uri in listOf(Uri.fromFile(File(app.filesDir, "secret")),
            Uri.parse("content://${app.packageName}.fileProvider/private/secret"))) {
            val messenger = FakeMessenger()
            val bridge = IncomingShareBridge(app, messenger)
            try {
                bridge.receive(Intent(Intent.ACTION_SEND).setType("image/png").putExtra(Intent.EXTRA_STREAM, uri))
                val packet = awaitPacket(messenger)
                assertEquals("unreadable", packet["error"])
                assertTrue((packet["files"] as List<*>).isEmpty())
            } finally { bridge.dispose() }
        }
    }

    @Test fun importsGrantedContentOnceSanitizesNamesAndAcknowledgementRemovesOnlyItsCopy() {
        val original = File.createTempFile("shared-", ".gif", app.cacheDir)
        val bytes = byteArrayOf(71, 73, 70, 56, 57, 97, 1, 2, 3)
        original.writeBytes(bytes)
        val uri = Uri.parse("content://incoming.test/sticker")
        val provider = object : ContentProvider() {
            override fun onCreate() = true
            override fun getType(uri: Uri) = "image/gif"
            override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, order: String?): Cursor =
                MatrixCursor(arrayOf(OpenableColumns.DISPLAY_NAME)).apply { addRow(arrayOf("../../safe.gif")) }
            override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor = ParcelFileDescriptor.open(original, ParcelFileDescriptor.MODE_READ_ONLY)
            override fun insert(uri: Uri, values: ContentValues?): Uri? = null
            override fun delete(uri: Uri, selection: String?, args: Array<out String>?) = 0
            override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = 0
        }
        provider.attachInfo(app, ProviderInfo().apply { authority = "incoming.test"; exported = true })
        ShadowContentResolver.registerProviderInternal("incoming.test", provider)
        val messenger = FakeMessenger()
        val bridge = IncomingShareBridge(app, messenger)
        try {
            val intent = Intent(Intent.ACTION_SEND_MULTIPLE).setType("image/*")
                .putParcelableArrayListExtra(Intent.EXTRA_STREAM, arrayListOf(uri, uri))
            bridge.receive(intent)
            val packet = awaitPacket(messenger)
            val files = packet["files"] as List<*>
            assertEquals(packet.toString(), 1, files.size)
            val file = files.single() as Map<*, *>
            assertEquals("safe.gif", file["name"])
            val imported = File(file["path"] as String)
            assertArrayEquals(bytes, imported.readBytes())
            messenger.invoke("ack", mapOf("id" to packet["id"]))
            waitUntil { !imported.exists() }
            assertArrayEquals(bytes, original.readBytes())
            assertNull(shadowOf(app).nextStartedActivity)
            // No declared size is trusted: enforce the cap while streaming.
            java.io.RandomAccessFile(original, "rw").use { it.setLength(33L * 1024 * 1024) }
            bridge.receive(intent)
            val tooLarge = awaitPacket(messenger)
            assertEquals("too_large", tooLarge["error"])
            assertTrue((tooLarge["files"] as List<*>).isEmpty())
        } finally { bridge.dispose(); original.delete() }
    }

    @Test fun ignoresNormalLaunchAndKeepsSeparateWarmSharesUntilAcknowledged() {
        val messenger = FakeMessenger()
        val bridge = IncomingShareBridge(app, messenger)
        try {
            bridge.receive(Intent(Intent.ACTION_MAIN))
            assertTrue((messenger.invoke("pending", null) as List<*>).isEmpty())
            for (text in listOf("one", "two")) bridge.receive(Intent(Intent.ACTION_SEND)
                .setType("text/plain").putExtra(Intent.EXTRA_TEXT, text))
            waitUntil { (messenger.invoke("pending", null) as List<*>).size == 2 &&
                (messenger.invoke("pending", null) as List<*>).all { (it as Map<*, *>)["loading"] == false } }
            val packets = messenger.invoke("pending", null) as List<*>
            assertEquals(listOf("one", "two"), packets.map { (it as Map<*, *>)["text"] })
            messenger.invoke("ack", mapOf("id" to (packets.first() as Map<*, *>)["id"]))
            assertEquals("two", ((messenger.invoke("pending", null) as List<*>).single() as Map<*, *>)["text"])
        } finally { bridge.dispose() }
    }

    private fun awaitPacket(messenger: FakeMessenger): Map<*, *> {
        waitUntil { (messenger.invoke("pending", null) as List<*>).firstOrNull()?.let { (it as Map<*, *>)["loading"] == false } == true }
        return (messenger.invoke("pending", null) as List<*>).first() as Map<*, *>
    }
    private fun waitUntil(condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + 5000
        while (!condition() && System.currentTimeMillis() < deadline) {
            Thread.sleep(10)
            shadowOf(Looper.getMainLooper()).idle()
        }
        assertTrue("asynchronous share import completed", condition())
    }
    private class FakeMessenger : BinaryMessenger {
        private var handler: BinaryMessenger.BinaryMessageHandler? = null
        override fun send(channel: String, message: ByteBuffer?) = Unit
        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) { this.handler = handler }
        fun invoke(method: String, args: Any?): Any? {
            val codec = StandardMethodCodec.INSTANCE
            val data = codec.encodeMethodCall(MethodCall(method, args)).apply { flip() }
            var response: ByteBuffer? = null
            checkNotNull(handler).onMessage(data) { response = it }
            return response?.let { it.flip(); codec.decodeEnvelope(it) }
        }
    }
}
