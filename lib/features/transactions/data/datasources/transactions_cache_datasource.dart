import '../models/transaction_model.dart';

class TransactionsCacheDataSource {
  final Map<String, List<TransactionModel>> _firstPageCache = {};

  List<TransactionModel>? readFirstPage(String uid) {
    return _firstPageCache[uid];
  }

  void writeFirstPage(String uid, List<TransactionModel> items) {
    _firstPageCache[uid] = items;
  }

  void clearUser(String uid) {
    _firstPageCache.remove(uid);
  }

  void clearAll() {
    _firstPageCache.clear();
  }
}
