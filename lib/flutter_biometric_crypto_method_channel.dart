import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'flutter_biometric_crypto_platform_interface.dart';

/// An implementation of [FlutterBiometricCryptoPlatform] that uses method channels.
class MethodChannelFlutterBiometricCrypto
    extends FlutterBiometricCryptoPlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _methodChannel = const MethodChannel(
    'flutter_biometric_crypto',
  );

  @override
  Future<void> initKey() async {
    try {
      await _methodChannel.invokeMethod<void>('initKey');
    } on PlatformException catch (e) {
      throw _convertPlatformException(e);
    }
  }

  @override
  Future<void> deleteKey() async {
    try {
      await _methodChannel.invokeMethod<void>('deleteKey');
    } on PlatformException catch (e) {
      throw _convertPlatformException(e);
    }
  }

  @override
  Future<Uint8List> encrypt(Uint8List data) async {
    try {
      final result = await _methodChannel.invokeMethod<Uint8List>(
        'encrypt',
        {'data': data},
      );
      if (result == null) {
        throw BiometricCryptoException('Encryption returned null');
      }
      return result;
    } on PlatformException catch (e) {
      throw _convertPlatformException(e);
    }
  }

  @override
  Future<Uint8List> decrypt(Uint8List encrypted) async {
    try {
      final result = await _methodChannel.invokeMethod<Uint8List>(
        'decrypt',
        {'encrypted': encrypted},
      );
      if (result == null) {
        throw BiometricCryptoException('Decryption returned null');
      }
      return result;
    } on PlatformException catch (e) {
      throw _convertPlatformException(e);
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isBiometricAvailable',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _convertPlatformException(e);
    }
  }

  Exception _convertPlatformException(PlatformException e) {
    final code = e.code;
    final message = e.message ?? 'Unknown error';

    switch (code) {
      case 'BIOMETRIC_NOT_AVAILABLE':
        return BiometricNotAvailableException(message);
      case 'BIOMETRIC_AUTHENTICATION_FAILED':
        return BiometricAuthenticationFailedException(message);
      case 'BIOMETRIC_ERROR':
        return BiometricCryptoException('Biometric error: $message');
      case 'KEY_NOT_FOUND':
        return KeyNotFoundException(message);
      case 'ENCRYPTION_FAILED':
        return EncryptionException(message);
      case 'DECRYPTION_FAILED':
        return DecryptionException(message);
      case 'DATA_TOO_LARGE':
        return DataTooLargeException(message);
      default:
        return BiometricCryptoException('Platform error: $message');
    }
  }
}

/// Base exception for biometric crypto operations.
class BiometricCryptoException implements Exception {
  final String message;
  BiometricCryptoException(this.message);

  @override
  String toString() => 'BiometricCryptoException: $message';
}

/// Exception thrown when biometric authentication is not available.
class BiometricNotAvailableException extends BiometricCryptoException {
  BiometricNotAvailableException(super.message);
}

/// Exception thrown when biometric authentication fails.
class BiometricAuthenticationFailedException
    extends BiometricCryptoException {
  BiometricAuthenticationFailedException(super.message);
}

/// Exception thrown when the key is not found.
class KeyNotFoundException extends BiometricCryptoException {
  KeyNotFoundException(super.message);
}

/// Exception thrown when encryption fails.
class EncryptionException extends BiometricCryptoException {
  EncryptionException(super.message);
}

/// Exception thrown when decryption fails.
class DecryptionException extends BiometricCryptoException {
  DecryptionException(super.message);
}

/// Exception thrown when data exceeds the maximum size limit.
class DataTooLargeException extends BiometricCryptoException {
  DataTooLargeException(super.message);
}

