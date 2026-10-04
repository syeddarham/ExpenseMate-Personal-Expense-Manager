import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class ExpenseState extends ChangeNotifier {
  final List<FinancialTransaction> _transactions = [
    FinancialTransaction(
      id: 'tx_1',
      title: 'Grocery Mart Shopping',
      amount: 68.50,
      type: TransactionType.expense,
      category: TransactionCategory.defaultCategories[1], // Groceries
      date: DateTime.now().subtract(const Duration(hours: 2)),
      account: 'Debit Card',
      note: 'Weekly essentials and fruits',
    ),
    FinancialTransaction(
      id: 'tx_2',
      title: 'Freelance Design Payment',
      amount: 850.00,
      type: TransactionType.income,
      category: TransactionCategory.defaultCategories[6], // Salary
      date: DateTime.now().subtract(const Duration(hours: 6)),
      account: 'Bank Account',
      note: 'Client invoice #1042',
    ),
    FinancialTransaction(
      id: 'tx_3',
      title: 'Coffee & Cafe Treats',
      amount: 14.20,
      type: TransactionType.expense,
      category: TransactionCategory.defaultCategories[0], // Food & Dining
      date: DateTime.now().subtract(const Duration(days: 1)),
      account: 'Cash',
    ),
    FinancialTransaction(
      id: 'tx_4',
      title: 'Electricity & Internet Bill',
      amount: 110.00,
      type: TransactionType.expense,
      category: TransactionCategory.defaultCategories[3], // Bills
      date: DateTime.now().subtract(const Duration(days: 2)),
      account: 'Bank Account',
    ),
    FinancialTransaction(
      id: 'tx_5',
      title: 'Cinema & Movie Popcorn',
      amount: 35.00,
      type: TransactionType.expense,
      category: TransactionCategory.defaultCategories[4], // Entertainment
      date: DateTime.now().subtract(const Duration(days: 3)),
      account: 'Debit Card',
    ),
    FinancialTransaction(
      id: 'tx_6',
      title: 'Monthly Salary Deposit',
      amount: 3200.00,
      type: TransactionType.income,
      category: TransactionCategory.defaultCategories[6], // Salary
      date: DateTime.now().subtract(const Duration(days: 5)),
      account: 'Bank Account',
    ),
  ];

  final List<Budget> _budgets = [
    Budget(
      id: 'b_1',
      title: 'Food & Dining',
      limitAmount: 200.0,
      spentAmount: 14.20,
      category: TransactionCategory.defaultCategories[0],
      month: DateTime.now(),
    ),
    Budget(
      id: 'b_2',
      title: 'Groceries',
      limitAmount: 250.0,
      spentAmount: 68.50,
      category: TransactionCategory.defaultCategories[1],
      month: DateTime.now(),
    ),
    Budget(
      id: 'b_3',
      title: 'Transport',
      limitAmount: 120.0,
      spentAmount: 45.0,
      category: TransactionCategory.defaultCategories[2],
      month: DateTime.now(),
    ),
    Budget(
      id: 'b_4',
      title: 'Bills & Utilities',
      limitAmount: 150.0,
      spentAmount: 110.0,
      category: TransactionCategory.defaultCategories[3],
      month: DateTime.now(),
    ),
    Budget(
      id: 'b_5',
      title: 'Entertainment',
      limitAmount: 80.0,
      spentAmount: 35.0,
      category: TransactionCategory.defaultCategories[4],
      month: DateTime.now(),
    ),
  ];

  String _currencySymbol = '\$';
  bool _isDarkMode = false;

  List<FinancialTransaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  String get currencySymbol => _currencySymbol;
  bool get isDarkMode => _isDarkMode;

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  void addTransaction(FinancialTransaction tx) {
    _transactions.insert(0, tx);

    // If expense, update the spentAmount in the corresponding budget
    if (tx.isExpense) {
      final index = _budgets.indexWhere((b) => b.category.id == tx.category.id);
      if (index != -1) {
        final currentBudget = _budgets[index];
        _budgets[index] = Budget(
          id: currentBudget.id,
          title: currentBudget.title,
          limitAmount: currentBudget.limitAmount,
          spentAmount: currentBudget.spentAmount + tx.amount,
          category: currentBudget.category,
          month: currentBudget.month,
        );
      }
    }

    notifyListeners();
  }

  void deleteTransaction(String id) {
    final txIndex = _transactions.indexWhere((tx) => tx.id == id);
    if (txIndex != -1) {
      final tx = _transactions[txIndex];
      if (tx.isExpense) {
        final bIndex = _budgets.indexWhere((b) => b.category.id == tx.category.id);
        if (bIndex != -1) {
          final b = _budgets[bIndex];
          _budgets[bIndex] = Budget(
            id: b.id,
            title: b.title,
            limitAmount: b.limitAmount,
            spentAmount: (b.spentAmount - tx.amount).clamp(0.0, double.infinity),
            category: b.category,
            month: b.month,
          );
        }
      }
      _transactions.removeAt(txIndex);
      notifyListeners();
    }
  }

  void setBudgetLimit(String categoryId, double newLimit) {
    final index = _budgets.indexWhere((b) => b.category.id == categoryId);
    if (index != -1) {
      final b = _budgets[index];
      _budgets[index] = Budget(
        id: b.id,
        title: b.title,
        limitAmount: newLimit,
        spentAmount: b.spentAmount,
        category: b.category,
        month: b.month,
      );
      notifyListeners();
    }
  }

  void setCurrency(String symbol) {
    _currencySymbol = symbol;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  /// Get spending grouped by category for analytics
  Map<TransactionCategory, double> getCategorySpending() {
    final Map<TransactionCategory, double> map = {};
    for (final tx in _transactions.where((tx) => tx.isExpense)) {
      final existingCat = map.keys.firstWhere(
        (c) => c.id == tx.category.id,
        orElse: () => tx.category,
      );
      map[existingCat] = (map[existingCat] ?? 0.0) + tx.amount;
    }
    return map;
  }
}
