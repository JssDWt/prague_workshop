# Breez SDK demo Prague

## Steps

### Create the app
```
flutter create name_your_app
```

### Remove the tests folder

### Remove comments in main.dart

### Change Android minSdkVersion
In `android/app/build.gradle` Change the line

```
minSdkVersion 18
```

### Add UI dependencies
```
  flutter_secure_storage: ^8.0.0
  bip39: ^1.0.6
  convert: ^3.1.1
  path_provider: ^2.0.15
  qr_flutter: ^4.1.0
```

### Add the UI
- Paste in the bottom of main.dart
```

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
```

- Rename `_counter` to `_balance` and set to -1.
- Rename the app title 

Put buttons underneith the balance text
```
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
```

### Add Breez SDK dependency
```
  breez_sdk:
    path: ../breez-sdk/libs/sdk-flutter
```

### Setup a node
Paste just underneith the imports:
```

import 'dart:typed_data';

import 'package:breez_sdk/breez_bridge.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';

Future _startBreezBridge() async {
  breezBridge.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  const secureStorage = FlutterSecureStorage();
  var glCert = await secureStorage.read(key: "gl-cert");
  var glKey = await secureStorage.read(key: "gl-key");
  var mnemonic = await secureStorage.read(key: "mnemonic");
  if (glCert != null && glKey != null && mnemonic != null) {
    await _initExistingNode(mnemonic, glCert, glKey);
  } else {
    await _initNewNode();
  }
  await breezBridge.startNode();
}

Future _initExistingNode(String mnemonic, String glCert, String glKey) async {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final sdkConfig = await _getConfig();
  await breezBridge.initServices(
    config: sdkConfig,
    seed: seed,
    creds: GreenlightCredentials(
      deviceCert: Uint8List.fromList(hex.decode(glCert)),
      deviceKey: Uint8List.fromList(hex.decode(glKey)),
    ),
  );
}

Future _initNewNode() async {
  const secureStorage = FlutterSecureStorage();
  final mnemonic = bip39.generateMnemonic();
  final seed = bip39.mnemonicToSeed(mnemonic);
  final sdkConfig = await _getConfig();

  final GreenlightCredentials creds = await breezBridge.registerNode(
    config: sdkConfig,
    network: Network.Bitcoin,
    seed: seed,
    inviteCode: ,
  );
  await secureStorage.write(
      key: "gl-cert", value: hex.encode(creds.deviceCert));
  await secureStorage.write(key: "gl-key", value: hex.encode(creds.deviceKey));
  await secureStorage.write(key: "mnemonic", value: mnemonic);
}

Future<Config> _getConfig() async {
  return (await breezBridge.defaultConfig(EnvironmentType.Production)).copyWith(
      workingDir: (await getApplicationDocumentsDirectory()).path,
      apiKey: );
}

```

### Initialize the Breez bridge
```
final breezBridge = BreezBridge();
void main() async {
  _startBreezBridge();
  runApp(const MyApp());
}
```

### Receive a payment
In ReceivePaymentDialog initState:

```
    breezBridge.invoicePaidStream.listen((event) {
      if (event.paymentHash == _paymentHash) {
        Navigator.of(context).pop();
      }
    });
    breezBridge
        .receivePayment(amountSats: 20000, description: "dev day prague")
        .then((value) => setState(
              () {
                _invoice = value.bolt11;
                _paymentHash = value.paymentHash;
              },
            ))
        .onError((error, stackTrace) =>
            debugPrint("ERROR in receivePayment: $error"));
```

### Send a payment
In SendPaymentDialog, after onPressed->setState
```
            breezBridge
                .sendPayment(bolt11: invoiceController.text)
                .then((_) => Navigator.of(context).pop())
                .onError((error, stackTrace) =>
                    debugPrint("ERROR in sendPayment: $error"));
```