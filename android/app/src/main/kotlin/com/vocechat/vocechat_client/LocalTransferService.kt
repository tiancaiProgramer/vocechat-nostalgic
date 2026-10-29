package com.vocechat.vocechat_client

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/** User-initiated file transfers only; never restarts an empty Flutter engine. */
class LocalTransferService : Service() {
    companion object { @Volatile var running = false; @Volatile var starting = false; val retained get() = running || starting; private const val CHANNEL = "local_file_transfers"; private const val ID = 41003 }
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= 26) getSystemService(NotificationManager::class.java)
            .createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.local_transfer_channel), NotificationManager.IMPORTANCE_LOW))
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        starting = false
        if (!BuildConfig.DIRECT_DISTRIBUTION_FEATURES || AppFlutterEngine.engine == null) { stopSelf(); return START_NOT_STICKY }
        val tap = PendingIntent.getActivity(this, 0, AppLaunchIntent.create(this), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val progress = intent?.getIntExtra("progress", -1) ?: -1
        val notification = NotificationCompat.Builder(this, CHANNEL).setSmallIcon(R.drawable.ic_background_message)
            .setContentTitle(getString(R.string.local_transfer_channel)).setContentText(getString(R.string.local_transfer_running))
            .setContentIntent(tap).setOngoing(true).setSilent(true).setOnlyAlertOnce(true)
            .setProgress(100, progress.coerceIn(0, 100), progress < 0).build()
        try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            else startForeground(ID, notification)
            running = true
        } catch (_: RuntimeException) { running = false; AppFlutterEngine.localTransferStopped(); stopSelf() }
        return START_NOT_STICKY
    }
    override fun onTimeout(startId: Int, fgsType: Int) { AppFlutterEngine.localTransferStopped(); stopSelf() }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onDestroy() { running = false; starting = false; stopForeground(STOP_FOREGROUND_REMOVE); AppFlutterEngine.serviceStopped(); super.onDestroy() }
}
