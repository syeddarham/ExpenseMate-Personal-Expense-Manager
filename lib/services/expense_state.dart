import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/currencies_data.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class ExpenseState extends ChangeNotifier {
  final List<FinancialTransaction> _transactions = [];
  final List<Budget> _budgets = [];
  final List<Account> _accounts = [];
  List<TransactionCategory> _categories = List.from(TransactionCategory.defaultCategories);

  String? _currencySymbol = '\$';
  String? _currencyCode = 'USD';
  bool _isLoading = false;

  ExpenseState() {
    _currencySymbol = '\$';
    _currencyCode = 'USD';
  }

  List<FinancialTransaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  String get currencySymbol {
    final dynamic s = _currencySymbol;
    if (s is String && s.isNotEmpty) return s;
    return '\$';
  }
  String get currencyCode {
    final dynamic c = _currencyCode;
    if (c is String && c.isNotEmpty) return c;
    return 'USD';
  }
  bool get isDarkMode => false;
  bool get isLoading => _isLoading;

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

  double get totalBalance {
    if (_accounts.isNotEmpty) {
      return _accounts.fold(0.0, (sum, acc) => sum + acc.balance);
    }
    return totalIncome - totalExpense;
  }

  /// Load initial data from the Node.js + MySQL backend
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch user profile & currency preference
      final user = await ApiService.getMe();
      if (user != null) {
        if (user.preferredCurrency.isNotEmpty) {
          _currencyCode = user.preferredCurrency.toUpperCase();
        }
        if (user.currencySymbol != null && user.currencySymbol!.isNotEmpty) {
          _currencySymbol = user.currencySymbol!;
        } else {
          _currencySymbol = AppCurrencies.getSymbol(_currencyCode ?? 'USD');
        }
        AppHelpers.currentCurrencySymbol = currencySymbol;
        if (user.primaryColor.isNotEmpty) {
          AppColors.setPrimary(AppColors.parseHex(user.primaryColor));
        }
      }

      // 2. Fetch categories strictly for this user
      final cats = await ApiService.getCategories();
      _categories = cats.isNotEmpty ? cats : List.from(TransactionCategory.defaultCategories);

      // 3. Fetch accounts
      final accs = await ApiService.getAccounts();
      _accounts.clear();
      _accounts.addAll(accs);

      // 4. Fetch transactions
      final txs = await ApiService.getTransactions();
      _transactions.clear();
      _transactions.addAll(txs);

      // 5. Fetch budgets
      final bgs = await ApiService.getBudgets();
      _budgets.clear();
      _budgets.addAll(bgs);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Add a transaction with backend sync
  Future<bool> addTransaction(FinancialTransaction tx) async {
    // Optimistically add to local state
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

    // Update account balance locally
    final accIndex = _accounts.indexWhere((a) => a.name.toLowerCase() == tx.account.toLowerCase());
    if (accIndex != -1) {
      final a = _accounts[accIndex];
      final delta = tx.type == TransactionType.income ? tx.amount : -tx.amount;
      _accounts[accIndex] = Account(
        id: a.id,
        name: a.name,
        type: a.type,
        openingBalance: a.openingBalance,
        balance: a.balance + delta,
      );
    }

    notifyListeners();

    // Call API backend
    final saved = await ApiService.addTransaction(tx);
    if (saved != null) {
      final idx = _transactions.indexOf(tx);
      if (idx != -1) {
        _transactions[idx] = saved;
      }
      return true;
    }
    return false;
  }

  /// Delete transaction with backend sync
  Future<bool> deleteTransaction(String id) async {
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

      // Revert account balance
      final accIndex = _accounts.indexWhere((a) => a.name.toLowerCase() == tx.account.toLowerCase());
      if (accIndex != -1) {
        final a = _accounts[accIndex];
        final delta = tx.type == TransactionType.income ? -tx.amount : tx.amount;
        _accounts[accIndex] = Account(
          id: a.id,
          name: a.name,
          type: a.type,
          openingBalance: a.openingBalance,
          balance: a.balance + delta,
        );
      }

      _transactions.removeAt(txIndex);
      notifyListeners();

      return await ApiService.deleteTransaction(id);
    }
    return false;
  }

  /// Set budget limit with backend sync
  Future<bool> setBudgetLimit(String categoryId, double newLimit) async {
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
    } else {
      final cat = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => TransactionCategory.defaultCategories.first,
      );
      _budgets.add(Budget(
        id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
        title: cat.name,
        limitAmount: newLimit,
        spentAmount: 0.0,
        category: cat,
        month: DateTime.now(),
      ));
      notifyListeners();
    }

    final ok = await ApiService.setBudget(categoryId: categoryId, limitAmount: newLimit);
    if (ok) {
      final fresh = await ApiService.getBudgets();
      _budgets.clear();
      _budgets.addAll(fresh);
      notifyListeners();
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Category Management
  // ---------------------------------------------------------------------------

  Future<TransactionCategory?> addCategory({
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) async {
    if (ApiService.hasToken) {
      final newCat = await ApiService.createCategory(
        name: name,
        icon: icon,
        color: color,
        isExpense: isExpense,
      );
      if (newCat != null) {
        _categories.add(newCat);
        notifyListeners();
        return newCat;
      }
    } else {
      final localCat = TransactionCategory(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        icon: TransactionCategory.parseIconName(icon),
        color: TransactionCategory.parseColorHex(color),
        isExpense: isExpense,
      );
      _categories.add(localCat);
      notifyListeners();
      return localCat;
    }
    return null;
  }

  Future<bool> editCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) async {
    if (ApiService.hasToken) {
      final updatedCat = await ApiService.updateCategory(
        id: id,
        name: name,
        icon: icon,
        color: color,
        isExpense: isExpense,
      );
      if (updatedCat != null) {
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = updatedCat;
        }
        _updateLocalCategoryReferences(updatedCat);
        notifyListeners();
        return true;
      }
      return false;
    } else {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updatedCat = TransactionCategory(
          id: id,
          name: name,
          icon: TransactionCategory.parseIconName(icon),
          color: TransactionCategory.parseColorHex(color),
          isExpense: isExpense,
        );
        _categories[index] = updatedCat;
        _updateLocalCategoryReferences(updatedCat);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<({bool success, String? error})> deleteCategory(String id) async {
    if (ApiService.hasToken) {
      final res = await ApiService.deleteCategory(id);
      if (res.success) {
        _categories.removeWhere((c) => c.id == id);
        _budgets.removeWhere((b) => b.category.id == id);
        notifyListeners();
        return (success: true, error: null);
      }
      return res;
    } else {
      _categories.removeWhere((c) => c.id == id);
      _budgets.removeWhere((b) => b.category.id == id);
      notifyListeners();
      return (success: true, error: null);
    }
  }

  void _updateLocalCategoryReferences(TransactionCategory updatedCat) {
    for (int i = 0; i < _transactions.length; i++) {
      if (_transactions[i].category.id == updatedCat.id) {
        final t = _transactions[i];
        _transactions[i] = FinancialTransaction(
          id: t.id,
          title: t.title,
          amount: t.amount,
          type: t.type,
          category: updatedCat,
          date: t.date,
          account: t.account,
          note: t.note,
          receiptUrl: t.receiptUrl,
        );
      }
    }

    for (int i = 0; i < _budgets.length; i++) {
      if (_budgets[i].category.id == updatedCat.id) {
        final b = _budgets[i];
        _budgets[i] = Budget(
          id: b.id,
          title: updatedCat.name,
          limitAmount: b.limitAmount,
          spentAmount: b.spentAmount,
          category: updatedCat,
          month: b.month,
        );
      }
    }
  }

  void setCurrency(String symbol, [String? code]) {
    _currencySymbol = symbol;
    if (code != null && code.isNotEmpty) {
      _currencyCode = code.toUpperCase();
    }
    AppHelpers.currentCurrencySymbol = symbol;
    notifyListeners();

    if (ApiService.hasToken) {
      ApiService.updateMe(
        currencySymbol: symbol,
        currencyCode: code,
      );
    }
  }

  Future<bool> changeCurrencyWithConversion({
    required String newCode,
    required String newSymbol,
    required bool convertAmounts,
    double rate = 1.0,
  }) async {
    final oldCode = currencyCode.toUpperCase();
    final targetCode = newCode.toUpperCase();
    final isSameCurrency = oldCode == targetCode;
    final shouldConvert = convertAmounts && !isSameCurrency && rate != 1.0;

    _currencyCode = targetCode;
    _currencySymbol = newSymbol;
    AppHelpers.currentCurrencySymbol = newSymbol;

    if (shouldConvert) {
      // Scale local in-memory transactions
      for (int i = 0; i < _transactions.length; i++) {
        final tx = _transactions[i];
        _transactions[i] = FinancialTransaction(
          id: tx.id,
          title: tx.title,
          amount: double.parse((tx.amount * rate).toStringAsFixed(2)),
          type: tx.type,
          category: tx.category,
          date: tx.date,
          account: tx.account,
          note: tx.note,
          receiptUrl: tx.receiptUrl,
        );
      }

      // Scale local in-memory accounts
      for (int i = 0; i < _accounts.length; i++) {
        final acc = _accounts[i];
        _accounts[i] = Account(
          id: acc.id,
          name: acc.name,
          type: acc.type,
          openingBalance: double.parse((acc.openingBalance * rate).toStringAsFixed(2)),
          balance: double.parse((acc.balance * rate).toStringAsFixed(2)),
        );
      }

      // Scale local in-memory budgets
      for (int i = 0; i < _budgets.length; i++) {
        final b = _budgets[i];
        _budgets[i] = Budget(
          id: b.id,
          title: b.title,
          limitAmount: double.parse((b.limitAmount * rate).toStringAsFixed(2)),
          spentAmount: double.parse((b.spentAmount * rate).toStringAsFixed(2)),
          category: b.category,
          month: b.month,
        );
      }
    }

    notifyListeners();

    if (ApiService.hasToken) {
      final success = await ApiService.convertCurrency(
        currencyCode: newCode,
        currencySymbol: newSymbol,
        convertAmounts: convertAmounts,
        rate: rate,
      );
      if (success) {
        await loadInitialData();
      }
      return success;
    }

    return true;
  }

  void toggleTheme(bool value) {}

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

  Color get primaryColor => AppColors.primary;

  Future<void> setPrimaryColor(Color color, {bool syncBackend = true}) async {
    AppColors.setPrimary(color);
    notifyListeners();

    if (syncBackend && ApiService.hasToken) {
      final hex = AppColors.toHex(color);
      await ApiService.updateMe(primaryColor: hex);
    }
  }

  void clear() {
    _transactions.clear();
    _budgets.clear();
    _accounts.clear();
    _categories = List.from(TransactionCategory.defaultCategories);
    _currencyCode = 'USD';
    _currencySymbol = '\$';
    AppHelpers.currentCurrencySymbol = '\$';
    AppColors.setPrimary(AppColors.defaultPrimary);
    _isLoading = false;
    notifyListeners();
  }
}
