import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help")),
      body: const Center(
        child: Text(
          "Here will be the help information.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
