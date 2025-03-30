import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class Expense {
  @HiveField(0)
  final String category;

  @HiveField(1)
  final String? description; // Optional field

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String wallet;

  @HiveField(5)
  final String userId; // Added user ID field

  Expense(this.category, this.description, this.amount, this.date, this.wallet, this.userId);
}
