package com.vocechat.vocechat_client

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class IncomingCallNotificationTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val manager get() = context.getSystemService(NotificationManager::class.java)
    @Before fun prepare() {
        MainActivity.foreground = false
        context.getSharedPreferences("background_messages", Context.MODE_PRIVATE).edit().clear()
            .putString("notificationSession", "server::1").commit()
        manager.cancelAll()
    }
    private fun ring(session: String = "server::1", ringing: Boolean = true) =
        IncomingCallNotification.update(context, session, "u-42", "Caller", ringing)

    @Test fun backgroundCallHasHighPriorityAndCorrectTapDestination() {
        assertTrue(ring())
        val notification = manager.activeNotifications.single().notification
        assertEquals(Notification.CATEGORY_CALL, notification.category)
        assertEquals(NotificationManager.IMPORTANCE_HIGH, manager.getNotificationChannel(IncomingCallNotification.CHANNEL).importance)
        val intent = shadowOf(notification.contentIntent).savedIntent
        assertEquals("u-42", intent.getStringExtra("background_target"))
        assertEquals("server::1", intent.getStringExtra("background_session"))
        assertEquals(30000L, notification.timeoutAfter)
        assertNull(notification.fullScreenIntent)
    }
    @Test fun refreshDoesNotDuplicateOrReplayAlert() {
        assertTrue(ring())
        assertTrue(ring())
        assertEquals(1, manager.activeNotifications.size)
        assertTrue(manager.activeNotifications.single().notification.flags and Notification.FLAG_ONLY_ALERT_ONCE != 0)
    }
    @Test fun hangupAndForegroundCancelNotification() {
        ring()
        assertFalse(ring(ringing = false))
        assertEquals(0, manager.activeNotifications.size)
        ring()
        MainActivity.foreground = true
        assertFalse(ring())
        assertEquals(0, manager.activeNotifications.size)
    }
    @Test fun oldAccountCannotCancelOrReplaceCurrentInvite() {
        ring()
        assertFalse(ring("old::1", false))
        assertEquals(1, manager.activeNotifications.size)
        assertFalse(ring("old::1"))
        assertEquals(1, manager.activeNotifications.size)
        MessageNotificationRouter.configure(context, "server::2", emptyList())
        assertEquals(0, manager.activeNotifications.size)
    }
    @Test fun disabledPushCancelsCallAndDisabledChannelStaysBlocked() {
        ring()
        context.getSharedPreferences("background_messages", Context.MODE_PRIVATE).edit().putBoolean("pushEnabled", false).commit()
        assertFalse(ring())
        assertEquals(0, manager.activeNotifications.size)
    }
}
