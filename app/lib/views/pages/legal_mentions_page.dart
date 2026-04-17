import 'package:flutter/material.dart';

class LegalMentionsPage extends StatelessWidget {
  const LegalMentionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentions légales')),
      body: const Center(child: Text('Page de mentions légales')),
    );
  }
}
