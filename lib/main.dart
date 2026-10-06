import 'qr_code_scanner.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioVisualiser',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: const MyHomePage(title: 'Scan QR Code in AudioVisualiser'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? qrCodeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text(qrCodeValue ?? 'You have not scanner a QR Code')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          qrCodeValue = await Navigator.push(context, MaterialPageRoute(builder: (context) => QrCodeScanner()));
          setState(() {});
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
