import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/currencies_data.dart';
import '../utils/helpers.dart';
import 'api_service.dart';
import 'auth_service.dart';

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

  String get _userCacheKey {
    final user = AuthService().currentUser;
    return user != null ? 'user_${user.id}' : 'default';
  }

  /// Load cached data instantly from device storage
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userCacheKey;

      final accStr = prefs.getString('cache_accounts_$key');
      final catStr = prefs.getString('cache_categories_$key');
      final txStr = prefs.getString('cache_transactions_$key');
      final bgStr = prefs.getString('cache_budgets_$key');
      final cCode = prefs.getString('cache_cur_code_$key');
      final cSym = prefs.getString('cache_cur_sym_$key');
      final colorHex = prefs.getString('cache_primary_color_$key');

      bool loadedAny = false;

      if (cCode != null && cCode.isNotEmpty) {
        _currencyCode = cCode;
      }
      if (cSym != null && cSym.isNotEmpty) {
        _currencySymbol = cSym;
        AppHelpers.currentCurrencySymbol = cSym;
      }
      if (colorHex != null && colorHex.isNotEmpty) {
        AppColors.setPrimary(AppColors.parseHex(colorHex));
      }

      if (accStr != null && accStr.isNotEmpty) {
        final List list = jsonDecode(accStr) as List;
        _accounts.clear();
        _accounts.addAll(list.map((j) => Account.fromJson(j as Map<String, dynamic>)));
        loadedAny = true;
      }

      if (catStr != null && catStr.isNotEmpty) {
        final List list = jsonDecode(catStr) as List;
        _categories = list.map((j) => TransactionCategory.fromJson(j as Map<String, dynamic>)).toList();
        loadedAny = true;
      }

      if (txStr != null && txStr.isNotEmpty) {
        final List list = jsonDecode(txStr) as List;
        _transactions.clear();
        _transactions.addAll(list.map((j) => FinancialTransaction.fromJson(j as Map<String, dynamic>)));
        loadedAny = true;
      }

      if (bgStr != null && bgStr.isNotEmpty) {
        final List list = jsonDecode(bgStr) as List;
        _budgets.clear();
        _budgets.addAll(list.map((j) => Budget.fromJson(j as Map<String, dynamic>)));
        loadedAny = true;
      }

      return loadedAny;
    } catch (_) {
      return false;
    }
  }

  /// Persist active state to local device storage
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userCacheKey;

      await prefs.setString('cache_accounts_$key', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
      await prefs.setString('cache_categories_$key', jsonEncode(_categories.map((c) => c.toJson()).toList()));
      await prefs.setString('cache_transactions_$key', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
      await prefs.setString('cache_budgets_$key', jsonEncode(_budgets.map((b) => b.toJson()).toList()));
      if (_currencyCode != null) await prefs.setString('cache_cur_code_$key', _currencyCode!);
      if (_currencySymbol != null) await prefs.setString('cache_cur_sym_$key', _currencySymbol!);
      await prefs.setString('cache_primary_color_$key', AppColors.toHex(AppColors.primary));
      await prefs.setInt('cache_timestamp_$key', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Load initial data with instant local caching to avoid unnecessary API calls
  Future<void> loadInitialData({bool forceRefresh = false}) async {
    final hadCache = await _loadFromCache();
    if (hadCache) {
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // Check cache freshness (15-minute lifespan)
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt('cache_timestamp_$_userCacheKey') ?? 0;
    final isStale = (DateTime.now().millisecondsSinceEpoch - lastTime) > (15 * 60 * 1000);

    // If cache is present and still fresh, avoid making API calls
    if (!forceRefresh && hadCache && !isStale) {
      return;
    }

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

      // 2. Fetch categories
      final cats = await ApiService.getCategories();
      if (cats.isNotEmpty) {
        _categories = cats;
      }

      // 3. Fetch accounts
      final accs = await ApiService.getAccounts();
      if (accs.isNotEmpty || _accounts.isEmpty) {
        _accounts.clear();
        _accounts.addAll(accs);
      }

      // 4. Fetch transactions
      final txs = await ApiService.getTransactions();
      _transactions.clear();
      _transactions.addAll(txs);

      // 5. Fetch budgets
      final bgs = await ApiService.getBudgets();
      _budgets.clear();
      _budgets.addAll(bgs);

      // Update cache with fresh data
      await _saveToCache();
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
    _saveToCache();

    // Call API backend
    final saved = await ApiService.addTransaction(tx);
    if (saved != null) {
      final idx = _transactions.indexOf(tx);
      if (idx != -1) {
        _transactions[idx] = saved;
      }
      _saveToCache();
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
      _saveToCache();

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
      _saveToCache();
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
      _saveToCache();
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

  // ---------------------------------------------------------------------------
  // Account Management (Dynamic CRUD)
  // ---------------------------------------------------------------------------

  Future<Account?> addAccount({
    required String name,
    required String type,
    double openingBalance = 0.0,
  }) async {
    if (ApiService.hasToken) {
      final newAcc = await ApiService.createAccount(
        name: name,
        type: type,
        openingBalance: openingBalance,
      );
      if (newAcc != null) {
        _accounts.add(newAcc);
        notifyListeners();
        _saveToCache();
        return newAcc;
      }
      return null;
    } else {
      final newAcc = Account(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: type,
        openingBalance: openingBalance,
        balance: openingBalance,
      );
      _accounts.add(newAcc);
      notifyListeners();
      _saveToCache();
      return newAcc;
    }
  }

  Future<Account?> updateAccount({
    required String id,
    required String name,
    required String type,
    double? openingBalance,
  }) async {
    if (ApiService.hasToken) {
      final updated = await ApiService.updateAccount(
        id: id,
        name: name,
        type: type,
        openingBalance: openingBalance,
      );
      if (updated != null) {
        final idx = _accounts.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _accounts[idx] = updated;
          notifyListeners();
          _saveToCache();
        }
        return updated;
      }
      return null;
    } else {
      final idx = _accounts.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final current = _accounts[idx];
        final delta = (openingBalance ?? current.openingBalance) - current.openingBalance;
        final updated = Account(
          id: id,
          name: name,
          type: type,
          openingBalance: openingBalance ?? current.openingBalance,
          balance: current.balance + delta,
        );
        _accounts[idx] = updated;
        notifyListeners();
        _saveToCache();
        return updated;
      }
      return null;
    }
  }

  Future<bool> deleteAccount(String id) async {
    if (ApiService.hasToken) {
      final ok = await ApiService.deleteAccount(id);
      if (ok) {
        _accounts.removeWhere((a) => a.id == id);
        notifyListeners();
        _saveToCache();
        return true;
      }
      return false;
    } else {
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
      _saveToCache();
      return true;
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
