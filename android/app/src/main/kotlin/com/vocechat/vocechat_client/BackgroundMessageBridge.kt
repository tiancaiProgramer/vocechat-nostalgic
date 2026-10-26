package com.vocechat.vocechat_client

import android.app.*
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Uses application context so notification delivery survives Activity destruction. */
class BackgroundMessageBridge(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "chat.voce/background")
    private val prefs = context.getSharedPreferences("background_messages", Context.MODE_PRIVATE)
    private var pendingTap: Map<String, String>? = null
    private var session = ""

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "fcmDiagnostic" -> {
                        val reason = call.argument<String>("reason") ?: ""
                        if (reason in listOf("token_ready", "token_timeout", "token_failed", "registration_failed",
                                "SERVICE_NOT_AVAILABLE", "AUTHENTICATION_FAILED", "API_KEY_ANDROID_APP_BLOCKED",
                                "API_KEY_INVALID", "FIS_AUTH_ERROR", "INSTALLATIONS_AUTH_ERROR", "PERMISSION_DENIED")) {
                            val status = call.argument<Number>("status")?.toInt()
                            android.util.Log.i("VoceFCM", "reason=$reason status=${status ?: 0}")
                        }
                        result.success(null)
                    }
                    "fcmState" -> {
                        val phase = call.argument<String>("phase") ?: "unavailable"
                        if (phase !in listOf("connecting", "registered", "standby", "disabled", "unavailable")) {
                            result.error("fcm_phase", "Unknown state", null)
                        } else {
                            check(prefs.edit().putString("fcmState", phase).commit())
                            android.util.Log.i("VoceFCM", "state=$phase")
                            result.success(null)
                        }
                    }
                    "takeTap" -> { result.success(pendingTap); pendingTap = null }
                    "status" -> {
                        MessageNotificationRouter.ensureChannel(context)
                        val manager = NotificationManagerCompat.from(context)
                        val channelsEnabled = if (Build.VERSION.SDK_INT >= 26) {
                            manager.getNotificationChannel(BackgroundMessageService.MESSAGES)?.importance != NotificationManager.IMPORTANCE_NONE
                        } else true
                        result.success(mapOf(
                            "enabled" to prefs.getBoolean("enabled", false),
                            "running" to BackgroundMessageService.running,
                            "pushEnabled" to prefs.getBoolean("pushEnabled", true),
                            "soundEnabled" to prefs.getBoolean("soundEnabled", true),
                            "mentionsOnly" to prefs.getBoolean("mentionsOnly", false),
                            "notifications" to (manager.areNotificationsEnabled() && channelsEnabled),
                            "batterySettingsVisited" to prefs.getBoolean("batterySettingsVisited", false),
                            "batteryExempt" to (Build.VERSION.SDK_INT < 23 ||
                                context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName))
                        ))
                    }
                    "notificationPreferences" -> {
                        val editor = prefs.edit()
                        for (key in listOf("pushEnabled", "soundEnabled", "mentionsOnly")) {
                            call.argument<Boolean>(key)?.let { editor.putBoolean(key, it) }
                        }
                        check(editor.commit()) { "Cannot save notification preferences" }
                        if (!prefs.getBoolean("pushEnabled", true)) clearMessages()
                        result.success(null)
                    }
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        check(prefs.edit().putBoolean("enabled", enabled).commit()) { "Cannot save preference" }
                        if (!enabled) stop()
                        result.success(null)
                    }
                    "sync" -> {
                        val nextSession = call.argument<String>("session") ?: ""
                        if (session != nextSession) {
                            clearMessages()
                            session = nextSession
                        }
                        if (session.isEmpty() || (!prefs.getBoolean("enabled", false) && call.argument<Boolean>("calling") != true)) stop()
                        else {
                            val intent = Intent(context, BackgroundMessageService::class.java)
                                .putExtra("calling", call.argument<Boolean>("calling") == true)
                            if (BackgroundMessageService.running) context.startService(intent)
                            else if (call.argument<Boolean>("background") != true) ContextCompat.startForegroundService(context, intent)
                        }
                        result.success(null)
                    }
                    "configureNotifications" -> {
                        MessageNotificationRouter.configure(context, call.argument<String>("session") ?: "",
                            call.argument<List<String>>("muted"))
                        result.success(null)
                    }
                    "notify" -> {
                        val account = call.argument<String>("session") ?: ""
                        val mid = call.argument<Number>("mid")?.toLong() ?: 0L
                        val present = call.argument<Boolean>("present") == true
                        // A queued Flutter delivery may arrive after the mode
                        // changed, including while a call keeps the service alive.
                        if (present && (!prefs.getBoolean("enabled", false) ||
                                !prefs.getBoolean("pushEnabled", true) ||
                                !BackgroundMessageService.running || session != account)) {
                            result.success(null)
                        } else {
                            MessageNotificationRouter.deliver(context, MessageNotification(
                                account, mid, call.argument<String>("target") ?: "",
                                call.argument<Number>("createdAt")?.toLong() ?: 0L,
                                call.argument<Number>("expiresAt")?.toLong(),
                                call.argument<String>("title") ?: "VoceChat", call.argument<String>("body") ?: "",
                                call.argument<Boolean>("mentioned") == true),
                                present = present, eligible = call.argument<Boolean>("eligible") == true)
                            result.success(null)
                        }
                    }
                    "notifyCall" -> {
                        IncomingCallNotification.update(context,
                            call.argument<String>("session") ?: "",
                            call.argument<String>("target") ?: "",
                            call.argument<String>("title") ?: "VoceChat",
                            call.argument<Boolean>("ringing") == true)
                        result.success(null)
                    }
                    "batterySettings" -> {
                        // Some OEMs (including Xiaomi) report false even after
                        // unrestricted battery use is enabled. A deliberate tap
                        // is sufficient; persist it even if the settings Intent fails.
                        check(prefs.edit().putBoolean("batterySettingsVisited", true).commit()) {
                            "Cannot save battery settings visit"
                        }
                        open(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:${context.packageName}")), Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(null)
                    }
                    "notificationSettings" -> {
                        MessageNotificationRouter.ensureChannel(context)
                        // A blocked app-wide permission must be enabled first.
                        // Otherwise open the chat-message category, not the
                        // foreground service's ongoing connection notification.
                        val intent = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(if (NotificationManagerCompat.from(context).areNotificationsEnabled())
                                Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS else Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                                .putExtra(Settings.EXTRA_CHANNEL_ID, BackgroundMessageService.MESSAGES)
                        } else appSettings()
                        open(intent, appSettings())
                        result.success(null)
                    }
                    "appSettings" -> { open(appSettings(), appSettings()); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("background_service", error.message, null)
            }
        }
    }

    fun notificationTap(intent: Intent?) {
        val target = intent?.getStringExtra("background_target") ?: return
        val account = intent.getStringExtra("background_session") ?: return
        intent.removeExtra("background_target")
        pendingTap = mapOf("target" to target, "session" to account)
        channel.invokeMethod("notificationTap", null)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingTap = null
    }

    private fun stop() {
        context.stopService(Intent(context, BackgroundMessageService::class.java))
        clearMessages()
    }

    private fun clearMessages() {
        MessageNotificationRouter.clear(context)
        IncomingCallNotification.clear(context)
    }

    private fun appSettings() = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
    private fun open(intent: Intent, fallback: Intent) {
        try { context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        catch (_: android.content.ActivityNotFoundException) { context.startActivity(fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
}
