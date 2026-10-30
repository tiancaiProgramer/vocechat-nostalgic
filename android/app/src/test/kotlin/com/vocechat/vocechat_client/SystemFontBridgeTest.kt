package com.vocechat.vocechat_client

import android.app.Application
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.FlutterException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.nio.ByteBuffer

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class SystemFontBridgeTest {
    private val application: Application get() = RuntimeEnvironment.getApplication()

    @Test fun olderAndroidSafelyFallsBackWithoutNewGraphicsApis() {
        val messenger = FakeMessenger()
        val bridge = SystemFontBridge(application, messenger)
        try {
            assertEquals(emptyList<Any>(), messenger.invoke("describe", null))
        } finally { bridge.dispose() }
        assertFalse(messenger.hasHandler)
    }

    @Test fun callerCannotReadAnArbitraryFileOrExpiredHandle() {
        val messenger = FakeMessenger()
        val bridge = SystemFontBridge(application, messenger)
        try {
            for (id in listOf(null, "/data/system/theme/fonts/Roboto-Regular.ttf", "expired")) {
                val error = assertThrows(FlutterException::class.java) {
                    messenger.invoke("read", mapOf("id" to id))
                }
                assertEquals("font_changed", error.code)
            }
            assertNull(messenger.invoke("unknown", null))
        } finally { bridge.dispose() }
    }

    private class FakeMessenger : BinaryMessenger {
        private var handler: BinaryMessenger.BinaryMessageHandler? = null
        val hasHandler: Boolean get() = handler != null

        override fun send(channel: String, message: ByteBuffer?) = Unit

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
            assertEquals("vocechat/system_font", channel)
            this.handler = handler
        }

        fun invoke(method: String, arguments: Any?): Any? {
            val codec = StandardMethodCodec.INSTANCE
            val call = codec.encodeMethodCall(MethodCall(method, arguments))
            call.flip()
            var envelope: ByteBuffer? = null
            var replied = false
            checkNotNull(handler).onMessage(call) { reply ->
                envelope = reply
                replied = true
            }
            check(replied) { "The platform method did not reply" }
            val reply = envelope ?: return null
            reply.flip()
            return codec.decodeEnvelope(reply)
        }
    }
}
