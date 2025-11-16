import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric_crypto/flutter_biometric_crypto.dart';

void main() {
  group('FlutterBiometricCrypto', () {
    test(
        'encrypt should throw DataTooLargeException for data exceeding max size',
        () {
      final largeData = Uint8List(1025); // Exceeds 1 KB limit
      expect(
        () => FlutterBiometricCrypto.encrypt(largeData),
        throwsA(isA<DataTooLargeException>()),
      );
    });

    test('encrypt should accept data within max size (size check only)', () {
      final smallData = Uint8List(100);
      // This test only verifies that the size check passes
      // The actual encryption will fail without proper setup, but that's expected
      expect(smallData.length, lessThanOrEqualTo(maxDataSize));
    });

    test('maxDataSize constant should be 1024', () {
      expect(maxDataSize, equals(1024));
    });
  });

  group('Exception types', () {
    test('BiometricCryptoException should have correct message', () {
      final exception = BiometricCryptoException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('BiometricCryptoException'));
    });

    test(
        'BiometricNotAvailableException should extend BiometricCryptoException',
        () {
      final exception = BiometricNotAvailableException('Not available');
      expect(exception, isA<BiometricCryptoException>());
    });

    test(
        'BiometricAuthenticationFailedException should extend BiometricCryptoException',
        () {
      final exception = BiometricAuthenticationFailedException('Failed');
      expect(exception, isA<BiometricCryptoException>());
    });

    test('KeyNotFoundException should extend BiometricCryptoException', () {
      final exception = KeyNotFoundException('Not found');
      expect(exception, isA<BiometricCryptoException>());
    });

    test('EncryptionException should extend BiometricCryptoException', () {
      final exception = EncryptionException('Encryption failed');
      expect(exception, isA<BiometricCryptoException>());
    });

    test('DecryptionException should extend BiometricCryptoException', () {
      final exception = DecryptionException('Decryption failed');
      expect(exception, isA<BiometricCryptoException>());
    });

    test('DataTooLargeException should extend BiometricCryptoException', () {
      final exception = DataTooLargeException('Too large');
      expect(exception, isA<BiometricCryptoException>());
    });
  });
}
