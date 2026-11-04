package com.vocechat.vocechat_client

import android.app.Application
import android.app.Service
import org.robolectric.Robolectric
import android.content.Context
import android.content.Intent
import android.os.UserManager
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
class BackgroundRestoreReceiverTest {
    private val app: Application get() = RuntimeEnvironment.getApplication()
    @Before fun prepare() {
        app.getSharedPreferences("background_messages", Context.MODE_PRIVATE).edit().clear().commit()
        shadowOf(app.getSystemService(UserManager::class.java)).setUserUnlocked(true)
    }
    private fun selected(enabled: Boolean, session: String) {
        app.getSharedPreferences("background_messages", Context.MODE_PRIVATE).edit()
            .putBoolean("enabled", enabled).putString("restore_session", session).commit()
    }
    class TestService : BackgroundMessageService() {
        var restored = false
        override fun restoreEngine() {
            check(BackgroundMessageService.running) { "Foreground promotion must precede engine initialization" }
            restored = true
        }
    }
    @Test fun nullIntentRestartPromotesAndRecreatesEngineThenStaysSticky() {
        selected(true, "test-server::1")
        val controller = Robolectric.buildService(TestService::class.java).create()
        try {
            assertEquals(Service.START_STICKY, controller.get().onStartCommand(null, 0, 1))
            assertTrue(controller.get().restored)
        } finally { controller.destroy() }
    }
    @Test fun disabledModeDoesNotResurrectEvenWithOldCallingFlag() {
        selected(false, "test-server::1")
        MainActivity.foreground = false
        val controller = Robolectric.buildService(TestService::class.java).create()
        try {
            assertEquals(Service.START_NOT_STICKY, controller.get().onStartCommand(
                Intent().putExtra("calling", true), 0, 1))
            assertFalse(controller.get().restored)
        } finally { controller.destroy() }
    }
    @Test fun bootRestoresSelectedModeWithoutOpeningAnActivityOrMicrophone() {
        selected(true, "test-server::1")
        BackgroundRestoreReceiver().onReceive(app, Intent(Intent.ACTION_BOOT_COMPLETED))
        val service = checkNotNull(shadowOf(app).nextStartedService)
        assertEquals(BackgroundMessageService::class.java.name, service.component?.className)
        assertFalse(service.getBooleanExtra("calling", false))
        assertNull(shadowOf(app).nextStartedActivity)
    }
    @Test fun appUpdateAlsoRestoresEnabledService() {
        selected(true, "test-server::1")
        BackgroundRestoreReceiver().onReceive(app, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))
        assertNotNull(shadowOf(app).nextStartedService)
    }
    @Test fun fcmModeAndSignedOutAccountsDoNotStartService() {
        for ((enabled, session) in listOf(false to "test-server::1", true to "")) {
            selected(enabled, session)
            BackgroundRestoreReceiver().onReceive(app, Intent(Intent.ACTION_BOOT_COMPLETED))
            assertNull(shadowOf(app).nextStartedService)
        }
    }
    @Test fun lockedStorageAndUnrelatedBroadcastsDoNotStartService() {
        selected(true, "test-server::1")
        shadowOf(app.getSystemService(UserManager::class.java)).setUserUnlocked(false)
        BackgroundRestoreReceiver().onReceive(app, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertNull(shadowOf(app).nextStartedService)
        shadowOf(app.getSystemService(UserManager::class.java)).setUserUnlocked(true)
        BackgroundRestoreReceiver().onReceive(app, Intent(Intent.ACTION_SCREEN_ON))
        assertNull(shadowOf(app).nextStartedService)
    }
}
