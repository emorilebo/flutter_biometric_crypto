# Build and Verification Instructions

This document provides step-by-step instructions to build and verify the `flutter_biometric_crypto` package.

## Prerequisites

1. **Flutter SDK**: Install Flutter 3.3.0 or higher
   ```bash
   flutter --version
   ```

2. **Android Studio** (for Android development)
   - Android SDK with API level 23 or higher
   - Kotlin support

3. **Xcode** (for iOS development, macOS only)
   - Xcode 12.0 or higher
   - iOS 12.0 or higher deployment target

4. **Physical Device or Emulator**
   - Android: Device/emulator with API 23+ and biometric sensor configured
   - iOS: Device/simulator with iOS 12.0+ and Face ID/Touch ID configured

## Building the Package

### 1. Install Dependencies

```bash
cd flutter_biometric_crypto
flutter pub get
```

### 2. Run Analysis

```bash
flutter analyze
```

### 3. Format Code

```bash
flutter format .
```

### 4. Run Unit Tests

```bash
flutter test
```

## Building the Example App

### Android

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Build the Android app:
   ```bash
   flutter build apk --debug
   ```

4. Run on device/emulator:
   ```bash
   flutter run
   ```

**Note**: For Android emulator, you need to configure biometric authentication:
- Open Android Emulator Settings
- Go to Security > Fingerprint
- Add a fingerprint

### iOS

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Install iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. Build the iOS app:
   ```bash
   flutter build ios --debug
   ```

5. Run on device/simulator:
   ```bash
   flutter run
   ```

**Note**: For iOS simulator, Face ID can be simulated:
- Hardware > Face ID > Enrolled
- Hardware > Face ID > Matching Face (to simulate success)

## Verification Steps

### 1. Key Generation Test

1. Launch the example app
2. Tap "Init Key" button
3. Verify status shows "Key initialized successfully"

**Expected Result**: Key is created without errors

### 2. Biometric Availability Test

1. Launch the example app
2. Check the status indicator
3. Verify it shows "Biometric Available" or "Biometric Not Available"

**Expected Result**: Correctly detects biometric availability

### 3. Encryption Test

1. Ensure key is initialized (tap "Init Key" if needed)
2. Tap "Encrypt Sample Data" button
3. Verify encrypted data (hex) is displayed

**Expected Result**: Data is encrypted and displayed in hex format

### 4. Decryption with Biometric Test

1. Ensure data is encrypted (from previous step)
2. Tap "Decrypt Data (Biometric Required)" button
3. Authenticate with biometric (fingerprint/face)
4. Verify decrypted data matches original: "Hello, Flutter Biometric Crypto!"

**Expected Result**: 
- Biometric prompt appears
- After successful authentication, data is decrypted
- Decrypted text matches original

### 5. Data Size Limit Test

1. Try to encrypt data larger than 1 KB
2. Verify error is thrown

**Expected Result**: `DataTooLargeException` is thrown

### 6. Key Deletion Test

1. Ensure key is initialized
2. Tap "Delete Key" button
3. Try to encrypt data
4. Verify error is thrown

**Expected Result**: 
- Key is deleted successfully
- Encryption fails with `KeyNotFoundException`

### 7. Round-Trip Encryption Test

Run the integration test:

```bash
flutter test test/integration_test.dart
```

**Expected Result**: 
- Key initialization succeeds
- Encryption succeeds
- Decryption succeeds (may require biometric on real device)
- Decrypted data equals original data

## Running Integration Tests

Integration tests require a real device or properly configured emulator:

```bash
flutter test test/integration_test.dart
```

**Note**: On emulators, you may need to simulate biometric authentication:
- **Android**: Use emulator settings to add fingerprints
- **iOS**: Use Hardware menu to simulate Face ID

## Troubleshooting

### Android Issues

1. **"Biometric not available"**
   - Ensure device/emulator has biometric sensor
   - Configure fingerprint in device settings
   - Verify `minSdkVersion` is 23 or higher

2. **"Key not found"**
   - Call `initKey()` before encrypting
   - Check Android Keystore is accessible
   - Verify app has proper permissions

3. **Build errors**
   - Clean build: `flutter clean`
   - Get dependencies: `flutter pub get`
   - Verify Android SDK is properly configured

### iOS Issues

1. **"Biometric not available"**
   - Ensure Face ID/Touch ID is set up
   - Verify `NSFaceIDUsageDescription` in Info.plist
   - Check device supports biometric authentication

2. **Build errors**
   - Clean build: `flutter clean`
   - Reinstall pods: `cd ios && pod install && cd ..`
   - Verify Xcode and iOS SDK are properly configured

3. **Code signing issues**
   - For testing, use `--no-codesign` flag
   - For device deployment, configure code signing in Xcode

## CI/CD Verification

The GitHub Actions workflow automatically:
1. Runs tests on multiple Flutter versions
2. Verifies code formatting
3. Runs static analysis
4. Builds Android and iOS examples

Check the `.github/workflows/ci.yml` file for the complete CI configuration.

## Security Verification

1. **Key Storage**: Verify keys are stored in secure hardware
   - Android: Check Android Keystore logs
   - iOS: Check Keychain access logs

2. **Biometric Prompt**: Verify biometric prompt appears before decryption
   - Test with wrong biometric (should fail)
   - Test with correct biometric (should succeed)

3. **Data Protection**: Verify encrypted data cannot be decrypted without key
   - Try decrypting with wrong key (should fail)
   - Verify key cannot be extracted from device

## Performance Testing

1. **Key Generation**: Measure time to generate key
   - Should complete in < 1 second

2. **Encryption**: Measure time to encrypt 1 KB data
   - Should complete in < 100ms

3. **Decryption**: Measure time to decrypt (including biometric)
   - Should complete in < 2 seconds (including user interaction)

## Next Steps

After verification:
1. Update version in `pubspec.yaml` if needed
2. Update `CHANGELOG.md` with changes
3. Create a release tag
4. Publish to pub.dev (if applicable)

