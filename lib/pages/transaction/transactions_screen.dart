import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../services/auth_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Screen 18: 18_Transactions Screen
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final PageController _cardPageController = PageController(viewportFraction: 0.9);
  int _currentCardIndex = 0;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF0F172A), Color(0xFF334155)],
    [Color(0xFF065F46), Color(0xFF10B981)],
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    [Color(0xFF581C87), Color(0xFF8B5CF6)],
  ];

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final accounts = expenseState.accounts;
    final transactions = expenseState.transactions;
    final userName = AuthService().currentUser?.name ?? 'ExpenseMate User';

    final totalCardsCount = accounts.isNotEmpty ? accounts.length : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: 'Transactions', showBack: true),
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
                onPageChanged: (idx) => setState(() => _currentCardIndex = idx),
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
            const SizedBox(height: AppSpacing.lg),

            // Last Transactions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: const Text(
                'Last Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted.withAlpha(120)),
                      const SizedBox(height: 12),
                      const Text(
                        'No transactions yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your recorded income and expenses will appear here.',
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
                  children: transactions.map((tx) {
                    final isIncome = !tx.isExpense;
                    final double amt = tx.amount;
                    final Color color = tx.category.color;

                    return Container(
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
                                Text(
                                  tx.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  '${tx.category.name} • ${tx.account}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
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
}
