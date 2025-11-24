package com.example.flutter_biometric_crypto

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.util.concurrent.Executor
import javax.crypto.Cipher

class FlutterBiometricCryptoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: FragmentActivity? = null
    private var executor: Executor? = null
    private val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore")
    private val keyAlias = "flutter_biometric_crypto_key"
    private val maxDataSize = 1024 // 1 KB

    init {
        keyStore.load(null)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_biometric_crypto")
        channel.setMethodCallHandler(this)
        executor = ContextCompat.getMainExecutor(flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initKey" -> {
                try {
                    initKey()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("INIT_FAILED", e.message, null)
                }
            }
            "deleteKey" -> {
                try {
                    deleteKey()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("DELETE_FAILED", e.message, null)
                }
            }
            "encrypt" -> {
                try {
                    val data = call.argument<ByteArray>("data")
                    if (data == null) {
                        result.error("INVALID_ARGUMENT", "Data is null", null)
                        return
                    }
                    if (data.size > maxDataSize) {
                        result.error("DATA_TOO_LARGE", "Data size exceeds maximum allowed size", null)
                        return
                    }
                    val encrypted = encrypt(data)
                    result.success(encrypted)
                } catch (e: Exception) {
                    result.error("ENCRYPTION_FAILED", e.message, null)
                }
            }
            "decrypt" -> {
                try {
                    val encrypted = call.argument<ByteArray>("encrypted")
                    if (encrypted == null) {
                        result.error("INVALID_ARGUMENT", "Encrypted data is null", null)
                        return
                    }

                    val title = call.argument<String>("title")
                    val subtitle = call.argument<String>("subtitle")
                    val description = call.argument<String>("description")
                    val negativeButtonText = call.argument<String>("negativeButtonText")

                    decrypt(encrypted, title, subtitle, description, negativeButtonText, result)
                } catch (e: Exception) {
                    result.error("DECRYPTION_FAILED", e.message, null)
                }
            }
            "isBiometricAvailable" -> {
                try {
                    val available = isBiometricAvailable()
                    result.success(available)
                } catch (e: Exception) {
                    result.error("BIOMETRIC_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun initKey() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            throw UnsupportedOperationException("Android API 23+ required")
        }

        if (keyStore.containsAlias(keyAlias)) {
            // Key already exists
            return
        }

        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_RSA,
            "AndroidKeyStore"
        )

        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setAlgorithmParameterSpec(
                java.security.spec.RSAKeyGenParameterSpec(
                    2048,
                    java.security.spec.RSAKeyGenParameterSpec.F4
                )
            )
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationValidityDurationSeconds(-1) // Require authentication for each use
            .build()

        keyPairGenerator.initialize(keyGenParameterSpec)
        keyPairGenerator.generateKeyPair()
    }

    private fun deleteKey() {
        if (keyStore.containsAlias(keyAlias)) {
            keyStore.deleteEntry(keyAlias)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun encrypt(data: ByteArray): ByteArray {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            throw UnsupportedOperationException("Android API 23+ required")
        }

        if (!keyStore.containsAlias(keyAlias)) {
            throw Exception("Key not found. Call initKey() first.")
        }

        val certificate = keyStore.getCertificate(keyAlias)
        if (certificate == null) {
            throw Exception("Certificate not found")
        }

        val publicKey = certificate.publicKey
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        return cipher.doFinal(data)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun decrypt(
        encrypted: ByteArray,
        title: String?,
        subtitle: String?,
        description: String?,
        negativeButtonText: String?,
        result: Result
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error("UNSUPPORTED", "Android API 23+ required", null)
            return
        }

        if (!keyStore.containsAlias(keyAlias)) {
            result.error("KEY_NOT_FOUND", "Key not found. Call initKey() first.", null)
            return
        }

        val privateKey = keyStore.getKey(keyAlias, null) as? PrivateKey
        if (privateKey == null) {
            result.error("KEY_NOT_FOUND", "Private key not found", null)
            return
        }

        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")

        try {
            cipher.init(Cipher.DECRYPT_MODE, privateKey)
            val decrypted = cipher.doFinal(encrypted)
            result.success(decrypted)
        } catch (e: Exception) {
            // If decryption fails due to authentication requirement, prompt for biometric
            if (e.message?.contains("User authentication required") == true ||
                e.message?.contains("Key user not authenticated") == true ||
                e.message?.contains("android.security.KeyStoreException") == true
            ) {
                promptBiometricAndDecrypt(
                    encrypted,
                    title,
                    subtitle,
                    description,
                    negativeButtonText,
                    result
                )
            } else {
                result.error("DECRYPTION_FAILED", e.message ?: "Decryption failed", null)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun promptBiometricAndDecrypt(
        encrypted: ByteArray,
        title: String?,
        subtitle: String?,
        description: String?,
        negativeButtonText: String?,
        result: Result
    ) {
        val activity = this.activity
        val executor = this.executor

        if (activity == null || executor == null) {
            result.error("BIOMETRIC_ERROR", "Activity or executor not available", null)
            return
        }

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult
                ) {
                    try {
                        val privateKey = keyStore.getKey(keyAlias, null) as? PrivateKey
                        if (privateKey == null) {
                            result.error("KEY_NOT_FOUND", "Private key not found", null)
                            return
                        }
                        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
                        cipher.init(Cipher.DECRYPT_MODE, privateKey)
                        val decrypted = cipher.doFinal(encrypted)
                        result.success(decrypted)
                    } catch (e: Exception) {
                        result.error("DECRYPTION_FAILED", e.message ?: "Decryption failed", null)
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    result.error(
                        "BIOMETRIC_AUTHENTICATION_FAILED",
                        "Biometric authentication failed: $errString",
                        null
                    )
                }

                override fun onAuthenticationFailed() {
                    result.error(
                        "BIOMETRIC_AUTHENTICATION_FAILED",
                        "Biometric authentication failed",
                        null
                    )
                }
            }
        )

        val promptInfoBuilder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title ?: "Biometric Authentication")
            .setSubtitle(subtitle ?: "Authenticate to decrypt data")
            .setNegativeButtonText(negativeButtonText ?: "Cancel")

        if (description != null) {
            promptInfoBuilder.setDescription(description)
        }

        biometricPrompt.authenticate(promptInfoBuilder.build())
    }

    private fun isBiometricAvailable(): Boolean {
        val context = activity?.applicationContext
        if (context == null) {
            return false
        }

        val biometricManager = BiometricManager.from(context)
        val canAuthenticate = biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        )

        return canAuthenticate == BiometricManager.BIOMETRIC_SUCCESS
    }
}

