package com.vocechat.vocechat_client

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.provider.Settings
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
import java.nio.ByteBuffer

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class MessageNotificationSettingsTest {
    private val app: Application get() = RuntimeEnvironment.getApplication()

    private fun withBridge(block: (Messenger) -> Unit) {
        val messenger = Messenger()
        val bridge = BackgroundMessageBridge(app, messenger)
        try { block(messenger) } finally { bridge.dispose() }
    }

    @Test fun opensChatMessagesBeforeTheBackgroundServiceHasEverStarted() = withBridge { messenger ->
        messenger.invoke("notificationSettings")
        val intent = checkNotNull(shadowOf(app).nextStartedActivity)
        assertEquals(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS, intent.action)
        assertEquals(app.packageName, intent.getStringExtra(Settings.EXTRA_APP_PACKAGE))
        assertEquals(BackgroundMessageService.MESSAGES, intent.getStringExtra(Settings.EXTRA_CHANNEL_ID))
        assertNotNull(app.getSystemService(NotificationManager::class.java)
            .getNotificationChannel(BackgroundMessageService.MESSAGES))
    }

    @Test fun disablingTheOngoingConnectionCategoryDoesNotBlockChatPermission() = withBridge { messenger ->
        val manager = app.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(BackgroundMessageService.CHANNEL,
            "Connection", NotificationManager.IMPORTANCE_NONE))
        val status = messenger.invoke("status") as Map<*, *>
        assertEquals(true, status["notifications"])
    }

    @Test fun disabledChatCategoryIsReportedEvenWhenConnectionCategoryIsEnabled() = withBridge { messenger ->
        val manager = app.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(BackgroundMessageService.CHANNEL,
            "Connection", NotificationManager.IMPORTANCE_LOW))
        manager.createNotificationChannel(NotificationChannel(BackgroundMessageService.MESSAGES,
            "Messages", NotificationManager.IMPORTANCE_NONE))
        assertEquals(false, (messenger.invoke("status") as Map<*, *>)["notifications"])
    }

    @Test fun disabledAppPermissionOpensTheAppNotificationSwitchFirst() = withBridge { messenger ->
        val manager = app.getSystemService(NotificationManager::class.java)
        shadowOf(manager).setNotificationsEnabled(false)
        assertEquals(false, (messenger.invoke("status") as Map<*, *>)["notifications"])
        messenger.invoke("notificationSettings")
        assertEquals(Settings.ACTION_APP_NOTIFICATION_SETTINGS, shadowOf(app).nextStartedActivity?.action)
    }

    @Test
    @Config(sdk = [24])
    fun olderAndroidWithoutChannelsOpensAppSettings() = withBridge { messenger ->
        messenger.invoke("notificationSettings")
        val intent = checkNotNull(shadowOf(app).nextStartedActivity)
        assertEquals(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, intent.action)
        assertEquals("package:${app.packageName}", intent.data.toString())
    }

    private class Messenger : BinaryMessenger {
        private var handler: BinaryMessenger.BinaryMessageHandler? = null
        override fun send(channel: String, message: ByteBuffer?) = Unit
        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
            assertEquals("chat.voce/background", channel)
            this.handler = handler
        }
        fun invoke(method: String): Any? {
            val codec = StandardMethodCodec.INSTANCE
            val request = codec.encodeMethodCall(MethodCall(method, null))
            request.flip()
            var response: ByteBuffer? = null
            checkNotNull(handler).onMessage(request) { response = it }
            val envelope = checkNotNull(response)
            envelope.flip()
            return codec.decodeEnvelope(envelope)
        }
    }
}
