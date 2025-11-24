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
      title: 'Flutter Biometric Crypto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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

  final _titleController = TextEditingController(text: 'Biometric Authentication');
  final _subtitleController = TextEditingController(text: 'Authenticate to decrypt data');
  final _descriptionController = TextEditingController(text: 'Please authenticate to access your sensitive data.');
  final _negativeButtonController = TextEditingController(text: 'Cancel');

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _negativeButtonController.dispose();
    super.dispose();
  }

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

      final promptInfo = BiometricPromptInfo(
        title: _titleController.text,
        subtitle: _subtitleController.text,
        description: _descriptionController.text,
        negativeButtonText: _negativeButtonController.text,
      );

      final decrypted = await FlutterBiometricCrypto.decrypt(
        encrypted,
        promptInfo: promptInfo,
      );
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
        _resetState();
      });
    } catch (e) {
      setState(() {
        _status = 'Error deleting key: $e';
      });
    }
  }

  void _resetState() {
    setState(() {
      _encryptedDataHex = null;
      _decryptedData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Biometric Crypto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check Availability',
            onPressed: _checkBiometricAvailability,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            Text(
              'Key Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initKey,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Init Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Key'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Operations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Customize Prompt'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(labelText: 'Subtitle'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: _negativeButtonController,
                        decoration: const InputDecoration(labelText: 'Negative Button'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _encryptData,
              icon: const Icon(Icons.lock),
              label: const Text('Encrypt Sample Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _decryptData,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Decrypt Data (Biometric Required)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _resetState,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset UI'),
            ),
            const SizedBox(height: 24),
            if (_encryptedDataHex != null) _buildEncryptedDataCard(context),
            if (_decryptedData != null) _buildDecryptedDataCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  _isBiometricAvailable ? Icons.check_circle : Icons.cancel,
                  color: _isBiometricAvailable ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isBiometricAvailable
                      ? 'Biometric Available'
                      : 'Biometric Not Available',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _isBiometricAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptedDataCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Encrypted Data (Hex)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                _encryptedDataHex!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecryptedDataCard(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Decrypted Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _decryptedData!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
