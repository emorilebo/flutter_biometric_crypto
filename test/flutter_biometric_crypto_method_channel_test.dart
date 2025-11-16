import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric_crypto/flutter_biometric_crypto_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFlutterBiometricCrypto', () {
    late MethodChannelFlutterBiometricCrypto plugin;
    const MethodChannel channel = MethodChannel('flutter_biometric_crypto');

    setUp(() {
      plugin = MethodChannelFlutterBiometricCrypto();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('initKey should handle success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initKey') {
          return null;
        }
        return null;
      });

      await expectLater(plugin.initKey(), completes);
    });

    test('initKey should convert platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initKey') {
          throw PlatformException(
            code: 'BIOMETRIC_NOT_AVAILABLE',
            message: 'Biometric not available',
          );
        }
        return null;
      });

      expect(
        () => plugin.initKey(),
        throwsA(isA<BiometricNotAvailableException>()),
      );
    });

    test('encrypt should handle success', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final expectedEncrypted = Uint8List.fromList([10, 20, 30]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'encrypt') {
          return expectedEncrypted;
        }
        return null;
      });

      final result = await plugin.encrypt(testData);
      expect(result, equals(expectedEncrypted));
    });

    test('encrypt should throw exception on null result', () async {
      final testData = Uint8List.fromList([1, 2, 3]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'encrypt') {
          return null;
        }
        return null;
      });

      expect(
        () => plugin.encrypt(testData),
        throwsA(isA<BiometricCryptoException>()),
      );
    });

    test('decrypt should convert BIOMETRIC_AUTHENTICATION_FAILED exception', () async {
      final testEncrypted = Uint8List.fromList([1, 2, 3]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'decrypt') {
          throw PlatformException(
            code: 'BIOMETRIC_AUTHENTICATION_FAILED',
            message: 'Authentication failed',
          );
        }
        return null;
      });

      expect(
        () => plugin.decrypt(testEncrypted),
        throwsA(isA<BiometricAuthenticationFailedException>()),
      );
    });

    test('isBiometricAvailable should return true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isBiometricAvailable') {
          return true;
        }
        return null;
      });

      final result = await plugin.isBiometricAvailable();
      expect(result, isTrue);
    });

    test('isBiometricAvailable should return false on null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isBiometricAvailable') {
          return null;
        }
        return null;
      });

      final result = await plugin.isBiometricAvailable();
      expect(result, isFalse);
    });
  });
}

