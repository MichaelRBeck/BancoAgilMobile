import 'package:bancoagil/pages/receipt_viewer_page.dart';
import 'package:flutter/material.dart';

class ReceiptAttachment extends StatelessWidget {
  final String? receiptBase64;
  final String? contentType;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const ReceiptAttachment({
    super.key,
    required this.receiptBase64,
    required this.contentType,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.attach_file),
          label: const Text('Anexar recibo'),
        ),
        const SizedBox(width: 12),
        if (receiptBase64 != null)
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 5),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptViewerPage(
                        base64Data: receiptBase64!,
                        contentType: contentType,
                      ),
                    ),
                  );
                },
                child: const Text('Visualizar'),
              ),
              const SizedBox(width: 16),
              TextButton(onPressed: onRemove, child: const Text('Remover')),
            ],
          ),
      ],
    );
  }
}
