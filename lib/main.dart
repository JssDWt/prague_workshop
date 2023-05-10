import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:typed_data';

import 'package:breez_sdk/breez_bridge.dart';
import 'package:breez_sdk/bridge_generated.dart' as sdk;
import 'package:breez_sdk/bridge_generated.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';

extension InitSDK on BreezBridge {
  Future start() async {
    const secureStorage = FlutterSecureStorage();
    var glCert = await secureStorage.read(key: "gl-cert");
    var glKey = await secureStorage.read(key: "gl-key");
    var mnemonic = await secureStorage.read(key: "mnemonic");
    if (glCert != null && glKey != null && mnemonic != null) {
      await _initExistingNode(mnemonic, glCert, glKey);
    } else {
      await _initNewNode();
    }
    await startNode();
  }

  Future _initExistingNode(String mnemonic, String glCert, String glKey) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final sdkConfig = await getConfig();
    await initServices(
      config: sdkConfig,
      seed: seed,
      creds: sdk.GreenlightCredentials(
        deviceCert: Uint8List.fromList(hex.decode(glCert)),
        deviceKey: Uint8List.fromList(hex.decode(glKey)),
      ),
    );
  }

  Future _initNewNode() async {
    const secureStorage = FlutterSecureStorage();
    final mnemonic = bip39.generateMnemonic();
    final seed = bip39.mnemonicToSeed(mnemonic);
    final sdkConfig = await getConfig();

    final sdk.GreenlightCredentials creds = await registerNode(
      config: sdkConfig,
      network: sdk.Network.Bitcoin,
      seed: seed,
      inviteCode: "?????",
    );
    await secureStorage.write(
        key: "gl-cert", value: hex.encode(creds.deviceCert));
    await secureStorage.write(
        key: "gl-key", value: hex.encode(creds.deviceKey));
    await secureStorage.write(key: "mnemonic", value: mnemonic);
  }

  Future<Config> getConfig() async {
    return (await defaultConfig(sdk.EnvironmentType.Production)).copyWith(
        workingDir: (await getApplicationDocumentsDirectory()).path,
        apiKey: "?????");
  }
}

void main() {
  BreezBridge breezBridge = BreezBridge();
  breezBridge.initialize();
  runApp(MyApp(breezBridge));
}

class MyApp extends StatelessWidget {
  final BreezBridge breezBridge;

  const MyApp(this.breezBridge, {super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => breezBridge.start(),
      lazy: false,
      child: MaterialApp(
        title: 'Breez SDK Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Breez SDK Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _balance = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_balance sat',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ReceivePaymentDialog(),
                      );
                    },
                    child: const Text("RECEIVE"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const SendPaymentDialog(),
                      );
                    },
                    child: const Text("SEND"),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ReceivePaymentDialog extends StatefulWidget {
  const ReceivePaymentDialog({super.key});

  @override
  State<ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends State<ReceivePaymentDialog> {
  String? _invoice;
  String? _paymentHash;

  @override
  void initState() {
    super.initState();
    _invoice = "random";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: AspectRatio(
          aspectRatio: 1,
          child: SizedBox(
            width: 230.0,
            height: 230.0,
            child: _invoice == null
                ? const Center(child: CircularProgressIndicator())
                : QrImageView(data: _invoice!.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

class SendPaymentDialog extends StatefulWidget {
  const SendPaymentDialog({super.key});

  @override
  State<SendPaymentDialog> createState() => _SendPaymentDialogState();
}

class _SendPaymentDialogState extends State<SendPaymentDialog> {
  final TextEditingController invoiceController = TextEditingController();
  bool _payInProgress = false;

  @override
  Widget build(BuildContext context) {
    if (_payInProgress) {
      return Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(
                height: 15,
              ),
              Text('Sending payment...')
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text("Send Payment"),
      content: TextField(
        decoration: const InputDecoration(label: Text("Paste invoice")),
        controller: invoiceController,
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text("OK"),
        ),
        TextButton(
          child: const Text("CANCEL"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
