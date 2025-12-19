import 'package:hive/hive.dart';

import '../models/transaction_model.dart';
import 'transaction_cache_model.dart';
import '../../../../core/security/hive_key_manager.dart';

class TransactionsCacheDataSource {
  static const String boxName = 'transactions_cache_v1';

  // ✅ Box dinâmica porque vamos salvar List<TransactionCacheModel>
  Future<Box<dynamic>> _box() async {
    final key = await HiveKeyManager.getOrCreateKey();
    return Hive.openBox<dynamic>(boxName, encryptionCipher: HiveAesCipher(key));
  }

  String _keyForFirstPage({
    required String uid,
    required String signature, // inclui filtros/tipo/data/cpf etc
  }) => 'user:$uid:firstPage:$signature';

  Future<List<TransactionModel>> readFirstPage({
    required String uid,
    required String signature,
  }) async {
    final box = await _box();

    final raw = box.get(_keyForFirstPage(uid: uid, signature: signature));
    if (raw == null) return const [];

    // ✅ Pode vir como List<dynamic>
    final list = (raw as List).cast<TransactionCacheModel>();
    if (list.isEmpty) return const [];

    return list
        .map(
          (c) => TransactionModel(
            id: c.id,
            userId: c.userId,
            type: c.type,
            category: c.category,
            amount: c.amount,
            date: c.date,
            notes: c.notes, // pode ser String? no seu TransactionModel
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> writeFirstPage({
    required String uid,
    required String signature,
    required List<TransactionModel> items,
  }) async {
    final box = await _box();

    final list = items
        .map(
          (t) => TransactionCacheModel(
            id: t.id,
            userId: t.userId,
            type: t.type,
            category: t.category,
            amount: t.amount,
            date: t.date,
            notes: t.notes,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
          ),
        )
        .toList(growable: false);

    await box.put(_keyForFirstPage(uid: uid, signature: signature), list);
  }

  Future<void> clearUser(String uid) async {
    final box = await _box();

    final keysToDelete = box.keys
        .where((k) => k.toString().startsWith('user:$uid:firstPage:'))
        .toList(growable: false);

    for (final k in keysToDelete) {
      await box.delete(k);
    }
  }

  // opcional (útil pra debug ou logout)
  Future<void> clearAll() async {
    final box = await _box();
    await box.clear();
  }
}
