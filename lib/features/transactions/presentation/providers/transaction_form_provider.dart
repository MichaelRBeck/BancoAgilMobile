import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/create_transfer.dart';
import '../../domain/usecases/update_transfer_notes.dart';

class TransactionFormProvider extends ChangeNotifier {
  final CreateTransaction createTx;
  final UpdateTransaction updateTx;
  final CreateTransfer createTransfer;
  final UpdateTransferNotes updateTransferNotes;

  TransactionFormProvider({
    required this.createTx,
    required this.updateTx,
    required this.createTransfer,
    required this.updateTransferNotes,
  });

  bool saving = false;
  String? error;

  String? receiptBase64;
  String? contentType;

  void setInitialReceipt({String? receiptBase64, String? contentType}) {
    this.receiptBase64 = receiptBase64;
    this.contentType = contentType;
    notifyListeners();
  }

  Future<void> pickReceipt() async {
    error = null;
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        File(x.path).absolute.path,
        minWidth: 1080,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        error = 'Não foi possível comprimir a imagem.';
        notifyListeners();
        return;
      }

      if (compressedBytes.length > 900 * 1024) {
        error = 'Recibo muito grande. Tente outra imagem/foto menor.';
        notifyListeners();
        return;
      }

      receiptBase64 = base64Encode(compressedBytes);
      contentType = 'image/jpeg';
      notifyListeners();
    } catch (e) {
      error = 'Erro ao anexar recibo: $e';
      notifyListeners();
    }
  }

  void removeReceipt() {
    receiptBase64 = null;
    contentType = null;
    notifyListeners();
  }

  Future<void> save({
    required String uid,
    required String originCpf, // necessário para transfer
    required bool isEditing,
    required Transaction? editing,
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    required String notes,
    required String destCpf,
  }) async {
    error = null;
    saving = true;
    notifyListeners();

    try {
      // TRANSFER
      if (type == 'transfer') {
        if (isEditing && editing != null) {
          await updateTransferNotes(uid: uid, id: editing.id, notes: notes);
          return;
        }

        await createTransfer(
          originUid: uid,
          originCpf: originCpf,
          destCpf: destCpf,
          amount: amount,
          description: notes,
        );
        return;
      }

      // INCOME/EXPENSE
      final now = DateTime.now();

      if (!isEditing) {
        final entity = Transaction(
          id: '', // ✅ AQUI: vazio para criar novo doc
          userId: uid,
          type: type,
          category: category,
          amount: amount,
          date: date,
          notes: notes,
          receiptBase64: receiptBase64,
          contentType: receiptBase64 != null ? contentType : null,
          createdAt: now,
          updatedAt: now,
        );
        await createTx(entity);
      } else {
        final old = editing!;
        final edited = Transaction(
          id: old.id,
          userId: old.userId,
          type: type,
          category: category,
          amount: amount,
          date: date,
          notes: notes,
          receiptBase64: receiptBase64,
          contentType: receiptBase64 != null ? contentType : null,
          createdAt: old.createdAt,
          updatedAt: now,
          originUid: old.originUid,
          destUid: old.destUid,
          originCpf: old.originCpf,
          destCpf: old.destCpf,
          status: old.status,
          counterpartyUid: old.counterpartyUid,
          counterpartyCpf: old.counterpartyCpf,
          counterpartyName: old.counterpartyName,
        );
        await updateTx(edited);
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
