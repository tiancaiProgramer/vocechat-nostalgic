package com.vocechat.vocechat_client

import android.util.Base64
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.ByteArrayInputStream
import java.security.KeyFactory
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LocalTransferIdentityTest {
    private fun decode(pem: String) = Base64.decode(pem.lines().filter { !it.startsWith("-----") }.joinToString(""), Base64.DEFAULT)
    @Test fun createsAValidSelfSignedCertificateAndMatchingPrivateKey() {
        val identity = LocalTransferIdentity.create()
        val certificate = CertificateFactory.getInstance("X.509")
            .generateCertificate(ByteArrayInputStream(decode(identity.getValue("certificate")))) as X509Certificate
        certificate.checkValidity()
        certificate.verify(certificate.publicKey)
        val key = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(decode(identity.getValue("privateKey"))))
        val signature = Signature.getInstance("SHA256withRSA").apply { initSign(key); update("test".toByteArray()) }.sign()
        assertTrue(Signature.getInstance("SHA256withRSA").apply { initVerify(certificate); update("test".toByteArray()) }.verify(signature))
    }
    @Test fun everySessionHasANewIdentity() {
        assertNotEquals(LocalTransferIdentity.create()["certificate"], LocalTransferIdentity.create()["certificate"])
    }
}
