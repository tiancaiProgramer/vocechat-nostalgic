package com.vocechat.vocechat_client

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.UserManager
import android.util.Log
import androidx.core.content.ContextCompat

/** Restore only the explicitly selected background mode after user unlock.
 * FCM mode, signed-out accounts, and force-stopped apps are not kept alive.
 */
class BackgroundRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED)) return
        if (!BuildConfig.DIRECT_DISTRIBUTION_FEATURES || !shouldRestore(context)) return
        try {
            ContextCompat.startForegroundService(context, Intent(context, BackgroundMessageService::class.java))
            Log.i("VoceBackground", "restore requested action=${intent.action}")
        } catch (error: RuntimeException) {
            Log.w("VoceBackground", "restore deferred: ${error.javaClass.simpleName}")
        }
    }

    companion object {
        internal fun shouldRestore(context: Context): Boolean {
            if (Build.VERSION.SDK_INT >= 24 && !context.getSystemService(UserManager::class.java).isUserUnlocked) return false
            val prefs = context.getSharedPreferences("background_messages", Context.MODE_PRIVATE)
            return prefs.getBoolean("enabled", false) && !prefs.getString("restore_session", "").isNullOrEmpty()
        }
    }
}
