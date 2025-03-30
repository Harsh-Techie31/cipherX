import 'package:hive/hive.dart';

part 'income_model.g.dart';

@HiveType(typeId: 1)
class Income {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String source;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  Income({
    required this.userId,
    required this.source,
    this.description,
    required this.amount,
    required this.date,
  });
}
