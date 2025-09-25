import 'dart:convert';
import 'package:flutter/material.dart';

class ReceiptViewerPage extends StatelessWidget {
  final String base64Data;
  final String? contentType;

  const ReceiptViewerPage({
    super.key,
    required this.base64Data,
    this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64Data);
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo')),
      body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
    );
  }
}
