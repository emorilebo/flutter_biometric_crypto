import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_biometric_crypto/flutter_biometric_crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Biometric Crypto Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BiometricCryptoPage(),
    );
  }
}

class BiometricCryptoPage extends StatefulWidget {
  const BiometricCryptoPage({super.key});

  @override
  State<BiometricCryptoPage> createState() => _BiometricCryptoPageState();
}

class _BiometricCryptoPageState extends State<BiometricCryptoPage> {
  String _status = 'Ready';
  String? _encryptedDataHex;
  String? _decryptedData;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await FlutterBiometricCrypto.isBiometricAvailable();
      setState(() {
        _isBiometricAvailable = available;
        _status = available
            ? 'Biometric authentication is available'
            : 'Biometric authentication is not available';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking biometric availability: $e';
      });
    }
  }

  Future<void> _initKey() async {
    setState(() {
      _status = 'Initializing key...';
    });

    try {
      await FlutterBiometricCrypto.initKey();
      setState(() {
        _status = 'Key initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing key: $e';
      });
    }
  }

  Future<void> _encryptData() async {
    setState(() {
      _status = 'Encrypting data...';
      _encryptedDataHex = null;
      _decryptedData = null;
    });

    try {
      // Sample data to encrypt
      const sampleText = 'Hello, Flutter Biometric Crypto!';
      final data = Uint8List.fromList(sampleText.codeUnits);

      final encrypted = await FlutterBiometricCrypto.encrypt(data);
      final hexString = encrypted
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(' ');

      setState(() {
        _encryptedDataHex = hexString;
        _status = 'Data encrypted successfully';
      });
    } on DataTooLargeException catch (e) {
      setState(() {
        _status = 'Error: Data too large - $e';
      });
    } on KeyNotFoundException catch (e) {
      setState(() {
        _status = 'Error: Key not found - $e. Please initialize key first.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error encrypting data: $e';
      });
    }
  }

  Future<void> _decryptData() async {
    if (_encryptedDataHex == null) {
      setState(() {
        _status = 'Please encrypt data first';
      });
      return;
    }

    setState(() {
      _status = 'Decrypting data (biometric authentication required)...';
      _decryptedData = null;
    });

    try {
      // Convert hex string back to bytes
      final hexParts = _encryptedDataHex!.split(' ');
      final encrypted = Uint8List.fromList(
        hexParts.map((hex) => int.parse(hex, radix: 16)).toList(),
      );

      final decrypted = await FlutterBiometricCrypto.decrypt(encrypted);
      final decryptedText = String.fromCharCodes(decrypted);

      setState(() {
        _decryptedData = decryptedText;
        _status = 'Data decrypted successfully';
      });
    } on BiometricNotAvailableException catch (e) {
      setState(() {
        _status = 'Error: Biometric not available - $e';
      });
    } on BiometricAuthenticationFailedException catch (e) {
      setState(() {
        _status = 'Error: Biometric authentication failed - $e';
      });
    } on KeyNotFoundException catch (e) {
      setState(() {
        _status = 'Error: Key not found - $e';
      });
    } catch (e) {
      setState(() {
        _status = 'Error decrypting data: $e';
      });
    }
  }

  Future<void> _deleteKey() async {
    setState(() {
      _status = 'Deleting key...';
    });

    try {
      await FlutterBiometricCrypto.deleteKey();
      setState(() {
        _status = 'Key deleted successfully';
        _encryptedDataHex = null;
        _decryptedData = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Error deleting key: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Biometric Crypto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isBiometricAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              _isBiometricAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isBiometricAvailable
                              ? 'Biometric Available'
                              : 'Biometric Not Available',
                          style: TextStyle(
                            color: _isBiometricAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initKey,
              child: const Text('Init Key'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _encryptData,
              child: const Text('Encrypt Sample Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _decryptData,
              child: const Text('Decrypt Data (Biometric Required)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _deleteKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Key'),
            ),
            const SizedBox(height: 16),
            if (_encryptedDataHex != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encrypted Data (Hex)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _encryptedDataHex!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_decryptedData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decrypted Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _decryptedData!,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
