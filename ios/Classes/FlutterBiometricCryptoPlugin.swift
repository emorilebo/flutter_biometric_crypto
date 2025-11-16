import Flutter
import UIKit
import LocalAuthentication
import Security

public class FlutterBiometricCryptoPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let keyAlias = "flutter_biometric_crypto_key"
    private let maxDataSize = 1024 // 1 KB
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_biometric_crypto",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterBiometricCryptoPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initKey":
            initKey(result: result)
        case "deleteKey":
            deleteKey(result: result)
        case "encrypt":
            guard let args = call.arguments as? [String: Any],
                  let data = args["data"] as? FlutterStandardTypedData else {
                result(FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "Data is null",
                    details: nil
                ))
                return
            }
            encrypt(data: Data(data.data), result: result)
        case "decrypt":
            guard let args = call.arguments as? [String: Any],
                  let encrypted = args["encrypted"] as? FlutterStandardTypedData else {
                result(FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "Encrypted data is null",
                    details: nil
                ))
                return
            }
            decrypt(encrypted: Data(encrypted.data), result: result)
        case "isBiometricAvailable":
            isBiometricAvailable(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initKey(result: @escaping FlutterResult) {
        // Check if key already exists
        if keyExists() {
            result(nil)
            return
        }
        
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryAny],
            nil
        )
        
        guard let accessControl = accessControl else {
            result(FlutterError(
                code: "INIT_FAILED",
                message: "Failed to create access control",
                details: nil
            ))
            return
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl,
            ],
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let errorMessage = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            result(FlutterError(
                code: "INIT_FAILED",
                message: "Failed to generate key: \(errorMessage)",
                details: nil
            ))
            return
        }
        
        result(nil)
    }
    
    private func deleteKey(result: @escaping FlutterResult) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            result(nil)
        } else {
            result(FlutterError(
                code: "DELETE_FAILED",
                message: "Failed to delete key: \(status)",
                details: nil
            ))
        }
    }
    
    private func encrypt(data: Data, result: @escaping FlutterResult) {
        if data.count > maxDataSize {
            result(FlutterError(
                code: "DATA_TOO_LARGE",
                message: "Data size exceeds maximum allowed size",
                details: nil
            ))
            return
        }
        
        guard let publicKey = getPublicKey() else {
            result(FlutterError(
                code: "KEY_NOT_FOUND",
                message: "Key not found. Call initKey() first.",
                details: nil
            ))
            return
        }
        
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data? else {
            let errorMessage = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            result(FlutterError(
                code: "ENCRYPTION_FAILED",
                message: "Encryption failed: \(errorMessage)",
                details: nil
            ))
            return
        }
        
        result(FlutterStandardTypedData(bytes: encrypted))
    }
    
    private func decrypt(encrypted: Data, result: @escaping FlutterResult) {
        guard let privateKey = getPrivateKey() else {
            result(FlutterError(
                code: "KEY_NOT_FOUND",
                message: "Key not found. Call initKey() first.",
                details: nil
            ))
            return
        }
        
        // Always authenticate before decrypting when using biometric-protected keys
        authenticateAndDecrypt(encrypted: encrypted, privateKey: privateKey, result: result)
    }
    
    private func authenticateAndDecrypt(
        encrypted: Data,
        privateKey: SecKey,
        result: @escaping FlutterResult
    ) {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        
        var authError: NSError?
        let reason = "Authenticate to decrypt data"
        
        // Try biometric first, fall back to device passcode if available
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        
        if context.canEvaluatePolicy(policy, error: &authError) {
            context.evaluatePolicy(
                policy,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        var decryptError: Unmanaged<CFError>?
                        if let decrypted = SecKeyCreateDecryptedData(
                            privateKey,
                            .rsaEncryptionPKCS1,
                            encrypted as CFData,
                            &decryptError
                        ) as Data? {
                            result(FlutterStandardTypedData(bytes: decrypted))
                        } else {
                            let errorMessage = decryptError?.takeRetainedValue().localizedDescription ?? "Unknown error"
                            result(FlutterError(
                                code: "DECRYPTION_FAILED",
                                message: "Decryption failed: \(errorMessage)",
                                details: nil
                            ))
                        }
                    } else {
                        let errorMessage = error?.localizedDescription ?? "Authentication failed"
                        result(FlutterError(
                            code: "BIOMETRIC_AUTHENTICATION_FAILED",
                            message: "Biometric authentication failed: \(errorMessage)",
                            details: nil
                        ))
                    }
                }
            }
        } else {
            // Try device passcode as fallback
            let passcodeContext = LAContext()
            if passcodeContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                passcodeContext.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                ) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            var decryptError: Unmanaged<CFError>?
                            if let decrypted = SecKeyCreateDecryptedData(
                                privateKey,
                                .rsaEncryptionPKCS1,
                                encrypted as CFData,
                                &decryptError
                            ) as Data? {
                                result(FlutterStandardTypedData(bytes: decrypted))
                            } else {
                                let errorMessage = decryptError?.takeRetainedValue().localizedDescription ?? "Unknown error"
                                result(FlutterError(
                                    code: "DECRYPTION_FAILED",
                                    message: "Decryption failed: \(errorMessage)",
                                    details: nil
                                ))
                            }
                        } else {
                            let errorMessage = error?.localizedDescription ?? "Authentication failed"
                            result(FlutterError(
                                code: "BIOMETRIC_AUTHENTICATION_FAILED",
                                message: "Authentication failed: \(errorMessage)",
                                details: nil
                            ))
                        }
                    }
                }
            } else {
                result(FlutterError(
                    code: "BIOMETRIC_NOT_AVAILABLE",
                    message: "Biometric authentication is not available",
                    details: nil
                ))
            }
        }
    }
    
    private func isBiometricAvailable(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        
        let available = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        
        result(available)
    }
    
    private func keyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
            kSecReturnRef as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }
    
    private func getPrivateKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return (item as! SecKey)
        }
        
        return nil
    }
    
    private func getPublicKey() -> SecKey? {
        guard let privateKey = getPrivateKey() else {
            return nil
        }
        
        return SecKeyCopyPublicKey(privateKey)
    }
}

