import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Screen 18: All Transactions Screen
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final PageController _cardPageController = PageController(viewportFraction: 0.9);
  final TextEditingController _searchController = TextEditingController();
  int _currentCardIndex = 0;
  String _searchQuery = '';
  int _selectedTypeFilter = 0; // 0: All, 1: Expenses, 2: Income
  String? _selectedAccountFilter;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF0F172A), Color(0xFF334155)],
    [Color(0xFF065F46), Color(0xFF10B981)],
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    [Color(0xFF581C87), Color(0xFF8B5CF6)],
  ];

  @override
  void dispose() {
    _cardPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTransactionDetails(BuildContext context, FinancialTransaction tx) {
    final expenseState = Provider.of<ExpenseState>(context, listen: false);
    final isIncome = !tx.isExpense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: tx.category.color.withAlpha(35),
                      child: Icon(tx.category.icon, size: 30, color: tx.category.color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${isIncome ? "+" : "-"}${AppHelpers.formatCurrency(tx.amount)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow('Category', tx.category.name),
              _buildDetailRow('Account', tx.account),
              _buildDetailRow('Date', AppHelpers.formatFriendlyDate(tx.date)),
              if (tx.note != null && tx.note!.isNotEmpty) _buildDetailRow('Note', tx.note!),
              if (tx.receiptUrl != null && tx.receiptUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Attached Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tx.receiptUrl!.startsWith('data:image') ? 'Captured Photo Receipt' : tx.receiptUrl!,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await expenseState.deleteTransaction(tx.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${tx.title}"')),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final accounts = expenseState.accounts;
    final allTransactions = expenseState.transactions;
    final userName = AuthService().currentUser?.name ?? 'ExpenseMate User';

    final totalCardsCount = accounts.isNotEmpty ? accounts.length : 1;

    // Filter transactions
    final filtered = allTransactions.where((tx) {
      if (_selectedTypeFilter == 1 && tx.type != TransactionType.expense) return false;
      if (_selectedTypeFilter == 2 && tx.type != TransactionType.income) return false;
      if (_selectedAccountFilter != null && _selectedAccountFilter!.isNotEmpty) {
        if (tx.account.toLowerCase() != _selectedAccountFilter!.toLowerCase()) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(q);
        final matchCategory = tx.category.name.toLowerCase().contains(q);
        final matchAccount = tx.account.toLowerCase().contains(q);
        final matchNote = (tx.note ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchCategory && !matchAccount && !matchNote) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: 'All Transactions', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Card PageView Carousel
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _cardPageController,
                itemCount: totalCardsCount,
                onPageChanged: (idx) {
                  setState(() {
                    _currentCardIndex = idx;
                    if (accounts.isNotEmpty && idx < accounts.length) {
                      _selectedAccountFilter = accounts[idx].name;
                    } else {
                      _selectedAccountFilter = null;
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final gradient = _cardGradients[index % _cardGradients.length];
                  final title = accounts.isNotEmpty ? accounts[index].name : 'Total Balance';
                  final amount = accounts.isNotEmpty ? accounts[index].balance : expenseState.totalBalance;
                  final type = accounts.isNotEmpty ? accounts[index].type.toUpperCase() : 'MAIN';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              type,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 15),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppHelpers.formatCurrency(amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontFamilyFallback: ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(userName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Carousel dots
            if (totalCardsCount > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalCardsCount, (idx) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentCardIndex == idx ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentCardIndex == idx ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            const SizedBox(height: AppSpacing.md),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search transactions, merchants, notes...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Type Filter Chips & Reset Account Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All (${allTransactions.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Expenses'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Income'),
                    if (_selectedAccountFilter != null) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: Icon(Icons.close, size: 14, color: AppColors.primary),
                        label: Text('Account: $_selectedAccountFilter', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        backgroundColor: AppColors.primaryLight,
                        onPressed: () => setState(() => _selectedAccountFilter = null),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} Transactions',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const Text(
                    'Tap to view • Swipe to delete',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted.withAlpha(120)),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching transactions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try clearing search filters or add a new transaction.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: filtered.map((tx) {
                    final isIncome = !tx.isExpense;
                    final double amt = tx.amount;
                    final Color color = tx.category.color;

                    return Dismissible(
                      key: Key('tx_${tx.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        expenseState.deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted "${tx.title}"')),
                        );
                      },
                      child: InkWell(
                        onTap: () => _showTransactionDetails(context, tx),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(tx.category.icon, color: color, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tx.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (tx.receiptUrl != null && tx.receiptUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(Icons.attach_file_rounded, size: 14, color: AppColors.primary),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.category.name} • ${tx.account} • ${AppHelpers.formatDate(tx.date)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${isIncome ? "+" : "-"}${AppHelpers.formatCurrency(amt)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isIncome ? AppColors.income : AppColors.expense,
                                  fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedTypeFilter == index;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      onSelected: (_) => setState(() => _selectedTypeFilter = index),
    );
  }
}
