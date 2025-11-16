# flutter_biometric_crypto

A Flutter package for biometric-protected encryption of small secrets using Android Keystore and iOS Keychain/Secure Enclave.

## Features

- 🔐 **Secure Key Storage**: Private keys are stored in Android Keystore (API ≥ 23) or iOS Keychain/Secure Enclave
- 👆 **Biometric Authentication**: Requires biometric authentication before decrypting data
- 🔑 **RSA 2048 Encryption**: Uses RSA 2048 key pairs for encryption/decryption
- 📦 **Small Data Only**: Optimized for encrypting small secrets (max 1 KB)
- 🛡️ **Production Ready**: Comprehensive error handling and security best practices

## Installation

Add `flutter_biometric_crypto` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_biometric_crypto: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

1. **Minimum SDK Version**: Ensure your `android/app/build.gradle` has `minSdkVersion 23` or higher:

```gradle
android {
    defaultConfig {
        minSdkVersion 23
    }
}
```

2. **Permissions**: The following permissions are automatically included in the plugin's `AndroidManifest.xml`:
   - `USE_BIOMETRIC`
   - `USE_FINGERPRINT`

3. **Dependencies**: Add the following to your `android/app/build.gradle`:

```gradle
dependencies {
    implementation "androidx.biometric:biometric:1.1.0"
}
```

### iOS

1. **Minimum iOS Version**: iOS 12.0 or higher is required.

2. **Face ID Usage Description**: Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to authenticate and decrypt your encrypted data securely.</string>
```

3. **Keychain Entitlements**: The plugin uses the Keychain which is available by default. For Secure Enclave support, ensure your app has the proper entitlements.

## Usage

### Basic Example

```dart
import 'package:flutter_biometric_crypto/flutter_biometric_crypto.dart';
import 'dart:typed_data';

// Initialize the key (call this once)
await FlutterBiometricCrypto.initKey();

// Check if biometric is available
final isAvailable = await FlutterBiometricCrypto.isBiometricAvailable();
if (!isAvailable) {
  print('Biometric authentication is not available');
  return;
}

// Encrypt data
final data = Uint8List.fromList('Hello, World!'.codeUnits);
final encrypted = await FlutterBiometricCrypto.encrypt(data);

// Decrypt data (will prompt for biometric authentication)
final decrypted = await FlutterBiometricCrypto.decrypt(encrypted);
final decryptedText = String.fromCharCodes(decrypted);
print(decryptedText); // Output: Hello, World!

// Delete the key when done
await FlutterBiometricCrypto.deleteKey();
```

### Error Handling

```dart
try {
  await FlutterBiometricCrypto.encrypt(data);
} on DataTooLargeException catch (e) {
  print('Data is too large: $e');
} on KeyNotFoundException catch (e) {
  print('Key not found. Call initKey() first: $e');
} on EncryptionException catch (e) {
  print('Encryption failed: $e');
}

try {
  await FlutterBiometricCrypto.decrypt(encrypted);
} on BiometricNotAvailableException catch (e) {
  print('Biometric not available: $e');
} on BiometricAuthenticationFailedException catch (e) {
  print('Biometric authentication failed: $e');
} on DecryptionException catch (e) {
  print('Decryption failed: $e');
}
```

## API Reference

### `initKey()`

Initialize or generate the key pair if it doesn't exist. This method should be called before using encryption/decryption.

**Returns**: `Future<void>`

**Throws**:
- `BiometricCryptoException` if initialization fails

### `deleteKey()`

Delete the key pair from secure storage. This permanently removes the key pair.

**Returns**: `Future<void>`

**Throws**:
- `BiometricCryptoException` if deletion fails

### `encrypt(Uint8List data)`

Encrypt data using the public key.

**Parameters**:
- `data`: The data to encrypt (must not exceed 1 KB)

**Returns**: `Future<Uint8List>` - The encrypted data

**Throws**:
- `DataTooLargeException` if data exceeds the size limit (1 KB)
- `KeyNotFoundException` if the key hasn't been initialized
- `EncryptionException` if encryption fails

### `decrypt(Uint8List encrypted)`

Decrypt data using the private key. This will prompt the user for biometric authentication before decrypting.

**Parameters**:
- `encrypted`: The encrypted data to decrypt

**Returns**: `Future<Uint8List>` - The decrypted data

**Throws**:
- `BiometricNotAvailableException` if biometric is not available
- `BiometricAuthenticationFailedException` if authentication fails
- `KeyNotFoundException` if the key hasn't been initialized
- `DecryptionException` if decryption fails

### `isBiometricAvailable()`

Check if biometric authentication is available and enrolled.

**Returns**: `Future<bool>` - `true` if biometric is available, `false` otherwise

## Limitations

1. **Data Size**: The package is designed for small secrets only. Maximum data size is 1 KB (1024 bytes). For larger data, consider using hybrid encryption (encrypt a symmetric key with this package, then use the symmetric key for the actual data).

2. **Platform Support**: Currently supports Android (API ≥ 23) and iOS (12.0+). Web, macOS, Windows, and Linux are not supported.

3. **Biometric Requirement**: Decryption always requires biometric authentication. There is no fallback to device credentials on Android (though iOS may fall back to device passcode).

4. **Key Persistence**: Keys are stored securely in platform-specific secure storage. If the user uninstalls the app or clears app data, the keys will be lost.

## Security Considerations

1. **Key Storage**: Private keys never leave the secure hardware (Android Keystore or iOS Secure Enclave when available). They cannot be extracted.

2. **Biometric Authentication**: Each decryption operation requires fresh biometric authentication. The key cannot be used without user authentication.

3. **Data Size Limit**: The 1 KB limit helps prevent misuse of the secure storage for large data, which could impact performance and security.

4. **Error Handling**: Always handle exceptions properly. Never log sensitive data or encryption keys.

## Testing

### Unit Tests

Run unit tests:

```bash
flutter test
```

### Integration Tests

Integration tests require a real device or emulator with biometric support:

```bash
flutter test test/integration_test.dart
```

**Note**: On Android emulators, you can simulate biometric authentication in the emulator settings. On iOS simulators, biometric authentication may not be fully supported.

## Example App

See the `example/` directory for a complete example app demonstrating all features.

To run the example:

```bash
cd example
flutter run
```

## Author

**Godfrey Lebo** - Software Developer, Car Racer, Debugger, Clean Architecture Enthusiast

- 📧 Email: [emorylebo@gmail.com](mailto:emorylebo@gmail.com)
- 💼 LinkedIn: [godfreylebo](https://www.linkedin.com/in/godfreylebo/)
- 🌐 Portfolio: [godfreylebo.vercel.app](https://godfreylebo.vercel.app/)
- 🐙 GitHub: [@emorilebo](https://github.com/emorilebo)

> Experienced Senior Fullstack Developer with over 6 years of professional experience specializing in Dart, JavaScript, and Rust. Proven track record of building scalable, high-performance applications.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Troubleshooting

### Android: "Biometric not available"

- Ensure your device has a fingerprint sensor or face unlock enabled
- Check that biometric authentication is set up in device settings
- Verify `minSdkVersion` is 23 or higher

### iOS: "Biometric not available"

- Ensure Face ID or Touch ID is set up on the device
- Verify `NSFaceIDUsageDescription` is added to `Info.plist`
- Check that the app has proper entitlements

### "Key not found" error

- Call `initKey()` before using encryption/decryption
- Ensure the app has proper permissions
- On Android, verify the device supports Android Keystore

### Decryption fails immediately

- This may happen if biometric authentication is required but not available
- Check `isBiometricAvailable()` before attempting decryption
- Ensure the user has enrolled biometrics on the device

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

