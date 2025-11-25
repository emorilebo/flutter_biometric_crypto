
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_biometric_crypto/flutter_biometric_crypto.dart';

/// Integration tests for flutter_biometric_crypto
///
/// These tests require a real device or emulator with biometric support.
/// They will test the actual encryption/decryption round-trip.
///
/// To run these tests:
/// 1. Ensure you have a device/emulator with biometric support
/// 2. Run: flutter test integration_test/flutter_biometric_crypto_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Tests', () {
    setUp(() async {
      // Clean up any existing keys before each test
      try {
        await FlutterBiometricCrypto.deleteKey();
      } catch (e) {
        // Ignore if key doesn't exist
      }
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await FlutterBiometricCrypto.deleteKey();
      } catch (e) {
        // Ignore if key doesn't exist
      }
    });

    testWidgets('initKey should create a key successfully',
        (WidgetTester tester) async {
      await FlutterBiometricCrypto.initKey();
    });

    testWidgets('isBiometricAvailable should return a boolean',
        (WidgetTester tester) async {
      final available = await FlutterBiometricCrypto.isBiometricAvailable();
      expect(available, isA<bool>());
    });

    testWidgets('encrypt and decrypt round-trip', (WidgetTester tester) async {
      // Initialize key
      await FlutterBiometricCrypto.initKey();

      // Original data
      final originalData = Uint8List.fromList(
        List.generate(100, (i) => i % 256),
      );

      // Encrypt
      final encrypted = await FlutterBiometricCrypto.encrypt(originalData);
      expect(encrypted, isNotEmpty);
      expect(encrypted.length, greaterThan(originalData.length));

      // Note: Decryption requires biometric authentication
      // This test will prompt for biometric on a real device
      // On emulator, you may need to simulate biometric success
      try {
        final decrypted = await FlutterBiometricCrypto.decrypt(encrypted);
        expect(decrypted, equals(originalData));
      } on BiometricAuthenticationFailedException {
        // This is expected if biometric authentication fails
        // In a real test environment, you would authenticate
        debugPrint('Biometric authentication failed or cancelled (expected in CI)');
      } on BiometricNotAvailableException {
        // Skip test if biometric is not available
        debugPrint('Biometric not available, skipping decryption verification');
      }
    });

    testWidgets('encrypt should fail with data too large',
        (WidgetTester tester) async {
      await FlutterBiometricCrypto.initKey();

      final largeData = Uint8List(maxDataSize + 1);
      expect(
        () => FlutterBiometricCrypto.encrypt(largeData),
        throwsA(isA<DataTooLargeException>()),
      );
    });

    testWidgets('encrypt should fail if key not initialized',
        (WidgetTester tester) async {
      // Ensure key is deleted
      try {
        await FlutterBiometricCrypto.deleteKey();
      } catch (e) {
        // Ignore
      }

      final data = Uint8List.fromList([1, 2, 3]);
      expect(
        () => FlutterBiometricCrypto.encrypt(data),
        throwsA(isA<KeyNotFoundException>()),
      );
    });

    testWidgets('deleteKey should remove the key', (WidgetTester tester) async {
      // Initialize key first
      await FlutterBiometricCrypto.initKey();

      // Delete key
      await FlutterBiometricCrypto.deleteKey();

      // Try to encrypt - should fail because key is deleted
      final data = Uint8List.fromList([1, 2, 3]);
      expect(
        () => FlutterBiometricCrypto.encrypt(data),
        throwsA(isA<KeyNotFoundException>()),
      );
    });
  });
}
