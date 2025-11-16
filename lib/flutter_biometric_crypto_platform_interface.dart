import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_biometric_crypto_method_channel.dart';

/// The interface that platform-specific implementations of flutter_biometric_crypto must extend.
abstract class FlutterBiometricCryptoPlatform extends PlatformInterface {
  /// Constructs a FlutterBiometricCryptoPlatform.
  FlutterBiometricCryptoPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterBiometricCryptoPlatform _instance =
      MethodChannelFlutterBiometricCrypto();

  /// The default instance of [FlutterBiometricCryptoPlatform] to use.
  static FlutterBiometricCryptoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBiometricCryptoPlatform] when
  /// they register themselves.
  static set instance(FlutterBiometricCryptoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize or generate the key pair if it doesn't exist.
  Future<void> initKey() {
    throw UnimplementedError('initKey() has not been implemented.');
  }

  /// Delete the key pair from secure storage.
  Future<void> deleteKey() {
    throw UnimplementedError('deleteKey() has not been implemented.');
  }

  /// Encrypt data using the public key.
  Future<Uint8List> encrypt(Uint8List data) {
    throw UnimplementedError('encrypt() has not been implemented.');
  }

  /// Decrypt data using the private key (requires biometric authentication).
  Future<Uint8List> decrypt(Uint8List encrypted,) {
    throw UnimplementedError('decrypt() has not been implemented.');
  }

  /// Check if biometric authentication is available and enrolled.
  Future<bool> isBiometricAvailable() {
    throw UnimplementedError(
        'isBiometricAvailable() has not been implemented.',);
  }
}
