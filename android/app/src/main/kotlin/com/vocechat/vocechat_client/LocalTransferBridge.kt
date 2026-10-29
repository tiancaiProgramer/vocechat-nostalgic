package com.vocechat.vocechat_client

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface
import java.net.Inet4Address
import java.util.Collections
import java.util.concurrent.Executors

internal class LocalTransferBridge(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "chat.voce/local_transfer")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var multicast: WifiManager.MulticastLock? = null
    @Volatile private var disposed = false
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> worker.execute {
                    try {
                        val identity = LocalTransferIdentity.create()
                        val addresses = mutableListOf<String>()
                        val broadcasts = mutableListOf<String>()
                        for (network in Collections.list(NetworkInterface.getNetworkInterfaces())) {
                            if (!network.isUp || network.isLoopback || network.name.startsWith("tun") ||
                                network.name.startsWith("rmnet") || network.name.startsWith("dummy")) continue
                            for (entry in network.interfaceAddresses) {
                                val address = entry.address
                                if (address is Inet4Address && address.isSiteLocalAddress) {
                                    addresses.add(address.hostAddress ?: continue)
                                    entry.broadcast?.hostAddress?.let { broadcasts.add(it) }
                                }
                            }
                        }
                        main.post {
                            if (!disposed) result.success(identity + mapOf("name" to Build.MODEL,
                                "addresses" to addresses.distinct(), "broadcasts" to broadcasts.distinct()))
                        }
                    } catch (_: Exception) { main.post { if (!disposed) result.error("local_transfer_init", "Unable to initialize local transfer", null) } }
                }
                "discovery" -> try {
                    if (call.argument<Boolean>("enabled") == true) {
                        if (multicast == null) {
                            val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            multicast = wifi.createMulticastLock("voce-local-transfer").apply { setReferenceCounted(false) }
                        }
                        if (multicast?.isHeld == false) multicast?.acquire()
                    } else releaseMulticast()
                    result.success(null)
                } catch (_: Exception) { result.error("local_transfer_network", "Unable to discover devices", null) }
                "active" -> try {
                    if (call.argument<Boolean>("enabled") == true) {
                        val intent = Intent(context, LocalTransferService::class.java)
                            .putExtra("progress", call.argument<Number>("progress")?.toInt() ?: -1)
                        if (LocalTransferService.running) context.startService(intent)
                        else { LocalTransferService.starting = true; ContextCompat.startForegroundService(context, intent) }
                    } else { LocalTransferService.starting = false; context.stopService(Intent(context, LocalTransferService::class.java)) }
                    result.success(null)
                } catch (_: Exception) { LocalTransferService.starting = false; result.error("local_transfer_service", "Unable to keep transfer running", null) }
                else -> result.notImplemented()
            }
        }
    }
    fun timedOut() { if (!disposed) channel.invokeMethod("stopped", null) }
    private fun releaseMulticast() { multicast?.let { if (it.isHeld) it.release() }; multicast = null }
    fun dispose() { disposed = true; releaseMulticast(); channel.setMethodCallHandler(null); worker.shutdownNow() }
}
