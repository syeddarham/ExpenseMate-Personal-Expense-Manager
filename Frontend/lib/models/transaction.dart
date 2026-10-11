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
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category'] is Map<String, dynamic>
          ? TransactionCategory.fromJson(json['category'] as Map<String, dynamic>)
          : TransactionCategory.defaultCategories.first,
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'] as String) ?? DateTime.now())
          : (json['transaction_date'] != null
              ? (DateTime.tryParse(json['transaction_date'] as String) ?? DateTime.now())
              : DateTime.now()),
      account: json['account'] as String? ?? json['account_name'] as String? ?? 'Cash',
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
      'category_id': category.id,
      'category': category.toJson(),
      'date': date.toIso8601String(),
      'account': account,
      'note': note,
      'receipt_url': receiptUrl,
    };
  }
}
