package com.vocechat.vocechat_client

import android.util.Base64
import java.io.ByteArrayInputStream
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.SecureRandom
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Ephemeral TLS identity. Keys stay in memory and never enter preferences/logs. */
internal object LocalTransferIdentity {
    fun create(): Map<String, String> {
        val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        val algorithm = seq(der(0x06, byteArrayOf(0x2a, 0x86.toByte(), 0x48, 0x86.toByte(),
            0xf7.toByte(), 0x0d, 0x01, 0x01, 0x0b)), der(0x05, byteArrayOf()))
        val name = seq(der(0x31, seq(der(0x06, byteArrayOf(0x55, 0x04, 0x03)),
            der(0x0c, "VoceChat Local Transfer".toByteArray(Charsets.UTF_8)))))
        val format = SimpleDateFormat("yyMMddHHmmss'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
        val now = System.currentTimeMillis()
        val validity = seq(der(0x17, format.format(Date(now - 86400000L)).toByteArray()),
            der(0x17, format.format(Date(now + 31536000000L)).toByteArray()))
        val tbs = seq(der(0xa0, der(0x02, byteArrayOf(2))),
            der(0x02, BigInteger(128, SecureRandom()).add(BigInteger.ONE).toByteArray()),
            algorithm, name, validity, name, pair.public.encoded)
        val signature = Signature.getInstance("SHA256withRSA").apply { initSign(pair.private); update(tbs) }.sign()
        val certificate = seq(tbs, algorithm, der(0x03, byteArrayOf(0) + signature))
        val parsed = CertificateFactory.getInstance("X.509")
            .generateCertificate(ByteArrayInputStream(certificate)) as X509Certificate
        parsed.verify(pair.public)
        return mapOf("certificate" to pem("CERTIFICATE", certificate),
            "privateKey" to pem("PRIVATE KEY", pair.private.encoded))
    }
    private fun pem(type: String, data: ByteArray) = "-----BEGIN $type-----\n" +
        Base64.encodeToString(data, Base64.NO_WRAP).chunked(64).joinToString("\n") + "\n-----END $type-----\n"
    private fun seq(vararg values: ByteArray) = der(0x30, values.fold(byteArrayOf()) { a, b -> a + b })
    private fun der(tag: Int, value: ByteArray): ByteArray {
        var length = value.size
        val bytes = mutableListOf<Byte>()
        if (length < 128) bytes.add(length.toByte()) else {
            val long = mutableListOf<Byte>()
            while (length > 0) { long.add(0, (length and 255).toByte()); length = length ushr 8 }
            bytes.add((0x80 or long.size).toByte()); bytes.addAll(long)
        }
        return byteArrayOf(tag.toByte()) + bytes.toByteArray() + value
    }
}
