package com.vocechat.vocechat_client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/** An invite is refreshed by live polling, never treated as a chat receipt. */
internal object IncomingCallNotification {
    const val CHANNEL = "incoming_calls"
    const val TAG = "voce-incoming-call"

    fun clear(context: Context) {
        NotificationManagerCompat.from(context).cancel(TAG, 0)
    }

    fun update(context: Context, session: String, target: String, title: String, ringing: Boolean): Boolean {
        val prefs = context.getSharedPreferences("background_messages", Context.MODE_PRIVATE)
        // Ignore an old scope/account's delayed callback without canceling the
        // current account's incoming call notification.
        if (session != prefs.getString("notificationSession", "")) return false
        if (!ringing || MainActivity.foreground || session.isEmpty() ||
            !Regex("u-[1-9][0-9]*").matches(target) || !prefs.getBoolean("pushEnabled", true)) {
            clear(context)
            return false
        }
        val manager = NotificationManagerCompat.from(context)
        if (Build.VERSION.SDK_INT >= 26) {
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, context.getString(R.string.incoming_calls), NotificationManager.IMPORTANCE_HIGH))
        }
        if (!manager.areNotificationsEnabled() ||
            (Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE)) return false
        val intent = AppLaunchIntent.create(context)
            .setAction("chat.voce.CALL")
            .setData(Uri.parse("vocechat-notification://call/${Uri.encode(session)}/$target"))
            .putExtra("background_target", target)
            .putExtra("background_session", session)
        val pending = PendingIntent.getActivity(context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_background_message)
            .setContentTitle(title.take(120))
            .setContentText(context.getString(R.string.incoming_call_body))
            .setContentIntent(pending).setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setOnlyAlertOnce(true)
            .setSilent(!prefs.getBoolean("soundEnabled", true))
            .setTimeoutAfter(30000).build()
        manager.notify(TAG, 0, notification)
        return true
    }
}
