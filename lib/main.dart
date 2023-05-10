import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breez SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Breez SDK Demo Home Page'),
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
