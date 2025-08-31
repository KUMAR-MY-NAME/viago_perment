import 'package:flutter/material.dart';

class CancellationRefundScreen extends StatelessWidget {
  const CancellationRefundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cancellation & Refund")),
      body: const Center(
        child: Text(
          "Here will be the information about cancellation and refund.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
