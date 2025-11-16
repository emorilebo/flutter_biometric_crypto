library flutter_biometric_crypto;

import 'dart:typed_data';
import 'flutter_biometric_crypto_platform_interface.dart';
import 'flutter_biometric_crypto_method_channel.dart';

export 'flutter_biometric_crypto_platform_interface.dart';
export 'flutter_biometric_crypto_method_channel.dart';

/// Maximum allowed data size for encryption (1 KB)
const int maxDataSize = 1024;

/// Main class for biometric-protected encryption.
///
/// This class provides a secure way to encrypt and decrypt small secrets
/// using biometric authentication. The private key is stored securely in
/// Android Keystore or iOS Keychain/Secure Enclave.
class FlutterBiometricCrypto {
  /// Initialize or generate the key pair if it doesn't exist.
  ///
  /// This method should be called before using encryption/decryption.
  /// It will generate a new RSA 2048 key pair if one doesn't exist,
  /// or do nothing if a key already exists.
  ///
  /// Throws [BiometricCryptoException] if initialization fails.
  static Future<void> initKey() async {
    return FlutterBiometricCryptoPlatform.instance.initKey();
  }

  /// Delete the key pair from secure storage.
  ///
  /// This permanently removes the key pair. After calling this,
  /// you'll need to call [initKey] again before encrypting/decrypting.
  ///
  /// Throws [BiometricCryptoException] if deletion fails.
  static Future<void> deleteKey() async {
    return FlutterBiometricCryptoPlatform.instance.deleteKey();
  }

  /// Encrypt data using the public key.
  ///
  /// [data] must not exceed [maxDataSize] (1 KB).
  ///
  /// Throws [DataTooLargeException] if data exceeds the size limit.
  /// Throws [KeyNotFoundException] if the key hasn't been initialized.
  /// Throws [EncryptionException] if encryption fails.
  static Future<Uint8List> encrypt(Uint8List data) async {
    if (data.length > maxDataSize) {
      throw DataTooLargeException(
        'Data size (${data.length} bytes) exceeds maximum allowed size ($maxDataSize bytes)',
      );
    }
    return FlutterBiometricCryptoPlatform.instance.encrypt(data);
  }

  /// Decrypt data using the private key.
  ///
  /// This will prompt the user for biometric authentication before decrypting.
  ///
  /// Throws [BiometricNotAvailableException] if biometric is not available.
  /// Throws [BiometricAuthenticationFailedException] if authentication fails.
  /// Throws [KeyNotFoundException] if the key hasn't been initialized.
  /// Throws [DecryptionException] if decryption fails.
  static Future<Uint8List> decrypt(Uint8List encrypted) async {
    return FlutterBiometricCryptoPlatform.instance.decrypt(encrypted);
  }

  /// Check if biometric authentication is available and enrolled.
  ///
  /// Returns `true` if biometric authentication is available and enrolled,
  /// `false` otherwise.
  static Future<bool> isBiometricAvailable() async {
    return FlutterBiometricCryptoPlatform.instance.isBiometricAvailable();
  }
}
