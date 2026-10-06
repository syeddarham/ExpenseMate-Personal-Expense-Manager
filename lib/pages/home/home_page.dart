import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/transaction_card.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../analytics/analytics_page.dart';
import '../budget/budget_page.dart';
import '../profile/profile_page.dart';
import '../transaction/add_transaction_page.dart';

/// Screen 02: Home / Dashboard Screen with integrated Tab Navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeDashboard(context),
          const AnalyticsPage(),
          const BudgetPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_main_fab',
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push<FinancialTransaction>(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionPage()),
          );
          if (!context.mounted) return;
          if (result != null) {
            Provider.of<ExpenseState>(context, listen: false).addTransaction(result);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${result.title}" successfully!'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
  );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final transactions = expenseState.transactions;
    final totalBalance = expenseState.totalBalance;
    final totalIncome = expenseState.totalIncome;
    final totalExpense = expenseState.totalExpense;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Avatar and Greeting
            _buildTopHeader(),
            const SizedBox(height: AppSpacing.lg),

            // Total Balance Card
            _buildTotalBalanceCard(totalBalance, totalIncome, totalExpense),
            const SizedBox(height: AppSpacing.lg),

            // Quick Action Shortcuts
            _buildQuickActions(),
            const SizedBox(height: AppSpacing.lg),

            // Recent Activity Section
            _buildRecentActivityHeader(transactions.length),
            const SizedBox(height: AppSpacing.sm),

            // Recent Transactions List
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions yet. Tap (+) to add one!'),
                ),
              )
            else
              ...transactions.take(6).map((tx) => Dismissible(
                    key: Key(tx.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.expense,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      expenseState.deleteTransaction(tx.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${tx.title}"'),
                          backgroundColor: AppColors.expense,
                        ),
                      );
                    },
                    child: TransactionCard(
                      transaction: tx,
                      onTap: () {
                        _showTransactionDetails(context, tx);
                      },
                    ),
                  )),
            const SizedBox(height: 80), // Padding for docked bottom nav
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, FinancialTransaction tx) {
    showModalBottomSheet(
      context: context,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tx.category.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(tx.category.icon, color: tx.category.color, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(tx.category.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    '${tx.isExpense ? "-" : "+"}${AppHelpers.formatCurrency(tx.amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: tx.isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Account / Source', tx.account),
              _buildDetailRow('Date & Time', AppHelpers.formatFriendlyDate(tx.date)),
              if (tx.note != null && tx.note!.isNotEmpty) _buildDetailRow('Note / Tag', tx.note!),
              const SizedBox(height: AppSpacing.lg),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    final user = AuthService().currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'User';
    final initials = userName.split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
    final pfp = user?.avatarUrl;

    ImageProvider? avatarProvider;
    if (pfp != null && pfp.isNotEmpty) {
      if (pfp.startsWith('data:image')) {
        try {
          final base64Part = pfp.split(',').last;
          avatarProvider = MemoryImage(base64Decode(base64Part));
        } catch (_) {}
      } else if (pfp.startsWith('http')) {
        avatarProvider = NetworkImage(pfp);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Text(
                      initials.isNotEmpty ? initials : 'EM',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const Text(
                  'Welcome to ExpenseMate',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(double totalBalance, double totalIncome, double totalExpense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('This Month', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppHelpers.formatCurrency(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Flow breakdown: Income & Expense
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.income.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Income', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              AppHelpers.formatCurrency(totalIncome),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expense', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              AppHelpers.formatCurrency(totalExpense),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(
          icon: Icons.add_circle_outline,
          label: 'Add',
          color: AppColors.primary,
          onTap: () async {
            final state = Provider.of<ExpenseState>(context, listen: false);
            final result = await Navigator.push<FinancialTransaction>(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionPage()),
            );
            if (result != null) {
              state.addTransaction(result);
            }
          },
        ),
        _buildActionItem(
          icon: Icons.pie_chart_outline_rounded,
          label: 'Budget',
          color: AppColors.accent,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _buildActionItem(
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          color: const Color(0xFF06B6D4),
          onTap: () => setState(() => _currentIndex = 1),
        ),
        _buildActionItem(
          icon: Icons.account_circle_outlined,
          label: 'Profile',
          color: const Color(0xFF8B5CF6),
          onTap: () => setState(() => _currentIndex = 3),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
        const Text(
          'Swipe left to delete',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_rounded, color: _currentIndex == 0 ? AppColors.primary : AppColors.textMuted),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: _currentIndex == 1 ? AppColors.primary : AppColors.textMuted),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 48), // Notch space for FAB
            IconButton(
              icon: Icon(Icons.account_balance_wallet_outlined,
                  color: _currentIndex == 2 ? AppColors.primary : AppColors.textMuted),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
            IconButton(
              icon: Icon(Icons.person_outline_rounded,
                  color: _currentIndex == 3 ? AppColors.primary : AppColors.textMuted),
              onPressed: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}
