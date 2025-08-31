import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: const Center(
        child: Text(
          "Here will be the wallet information.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
