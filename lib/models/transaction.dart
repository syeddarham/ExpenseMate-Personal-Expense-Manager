import 'category.dart';

enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String account;
  final String? note;
  final String? receiptUrl;

  FinancialTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.account,
    this.note,
    this.receiptUrl,
  });

  bool get isExpense => type == TransactionType.expense;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: TransactionCategory.fromJson(json['category'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      account: json['account'] as String? ?? 'Cash',
      note: json['note'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category.toJson(),
      'date': date.toIso8601String(),
      'account': account,
      'note': note,
      'receipt_url': receiptUrl,
    };
  }
}
