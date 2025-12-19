import 'package:hive/hive.dart';

part 'transaction_cache_model.g.dart';

@HiveType(typeId: 0)
class TransactionCacheModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  const TransactionCacheModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
