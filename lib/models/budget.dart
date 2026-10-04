import 'category.dart';

class Budget {
  final String id;
  final String title;
  final double limitAmount;
  final double spentAmount;
  final TransactionCategory category;
  final DateTime month;

  Budget({
    required this.id,
    required this.title,
    required this.limitAmount,
    required this.spentAmount,
    required this.category,
    required this.month,
  });

  double get remainingAmount => (limitAmount - spentAmount).clamp(0.0, limitAmount);
  double get progressPercentage => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spentAmount > limitAmount;
  bool get isNearLimit => progressPercentage >= 0.85 && !isExceeded;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      title: json['title'] as String,
      limitAmount: (json['limit_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      category: TransactionCategory.fromJson(json['category'] as Map<String, dynamic>),
      month: DateTime.parse(json['month'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
      'category': category.toJson(),
      'month': month.toIso8601String(),
    };
  }
}
