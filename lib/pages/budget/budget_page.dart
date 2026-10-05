import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../components/budget_progress_bar.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../category/categories_page.dart';

/// Screen 04: Budget Management
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  void _showAdjustBudgetModal(BuildContext context, Budget budget) {
    final controller = TextEditingController(text: budget.limitAmount.toStringAsFixed(0));
    final expenseState = Provider.of<ExpenseState>(context, listen: false);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: budget.category.color.withAlpha(40),
                            child: Icon(budget.category.icon, size: 18, color: budget.category.color),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${budget.title} Limit',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Current spent: ${AppHelpers.formatCurrency(budget.spentAmount)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: 'Monthly Limit Amount',
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: 'Update Limit',
                    isLoading: isSaving,
                    onPressed: () async {
                      final newLimit = double.tryParse(controller.text.trim());
                      if (newLimit != null && newLimit >= 0) {
                        setModalState(() => isSaving = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        await expenseState.setBudgetLimit(budget.category.id, newLimit);
                        if (!mounted) return;
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Budget for ${budget.title} updated to ${AppHelpers.formatCurrency(newLimit)}'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        setModalState(() => isSaving = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        await expenseState.setBudgetLimit(budget.category.id, 0);
                        if (!mounted) return;
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Budget for ${budget.title} removed.'),
                            backgroundColor: AppColors.textSecondary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                      label: const Text('Remove Budget Limit', style: TextStyle(color: AppColors.expense, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSetCategoryBudgetModal(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context, listen: false);
    final expenseCategories = expenseState.categories.where((c) => c.isExpense).toList();

    if (expenseCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an expense category first.')),
      );
      return;
    }

    TransactionCategory selectedCat = expenseCategories.first;
    // Check if selectedCat already has a limit
    final existingBudget = expenseState.budgets.where((b) => b.category.id == selectedCat.id).firstOrNull;
    final controller = TextEditingController(
      text: existingBudget != null && existingBudget.limitAmount > 0
          ? existingBudget.limitAmount.toStringAsFixed(0)
          : '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set Category Budget',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Select Expense Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),

                  // Category Selector Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCat.id,
                        items: expenseCategories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: c.color.withAlpha(40),
                                  child: Icon(c.icon, size: 14, color: c.color),
                                ),
                                const SizedBox(width: 10),
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final cat = expenseCategories.firstWhere((c) => c.id == val);
                            setModalState(() {
                              selectedCat = cat;
                              final b = expenseState.budgets.where((b) => b.category.id == cat.id).firstOrNull;
                              controller.text = b != null && b.limitAmount > 0 ? b.limitAmount.toStringAsFixed(0) : '';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  CustomTextField(
                    label: 'Monthly Limit Amount',
                    hint: 'e.g. 500',
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  CustomButton(
                    label: 'Save Budget Limit',
                    isLoading: isSaving,
                    onPressed: () async {
                      final limit = double.tryParse(controller.text.trim());
                      if (limit == null || limit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid monthly limit')),
                        );
                        return;
                      }

                      setModalState(() => isSaving = true);
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await expenseState.setBudgetLimit(selectedCat.id, limit);
                      if (!mounted) return;
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Budget for ${selectedCat.name} set to ${AppHelpers.formatCurrency(limit)}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    // Show active budgets that have a positive limit
    final activeBudgets = expenseState.budgets.where((b) => b.limitAmount > 0).toList();

    final totalBudget = activeBudgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = activeBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    // Check for alerts
    final exceededBudgets = activeBudgets.where((b) => b.isExceeded).toList();
    final warningBudgets = activeBudgets.where((b) => b.isNearLimit).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Monthly Budget',
        actions: [
          IconButton(
            icon: Icon(Icons.category_outlined, color: AppColors.primary),
            tooltip: 'Manage Categories',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budget_page_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showSetCategoryBudgetModal(context),
        icon: const Icon(Icons.add_chart),
        label: const Text('Set Budget', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Budget Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppShadows.elevated,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Monthly Budget',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppHelpers.formatCurrency(totalSpent)} / ${AppHelpers.formatCurrency(totalBudget)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      backgroundColor: Colors.white.withAlpha(50),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(1)}% consumed',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${AppHelpers.formatCurrency((totalBudget - totalSpent).clamp(0.0, totalBudget))} left',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Alerts Banner if any budget is exceeded or near limit
            if (exceededBudgets.isNotEmpty || warningBudgets.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: exceededBudgets.isNotEmpty ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: exceededBudgets.isNotEmpty ? AppColors.expense : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: exceededBudgets.isNotEmpty ? AppColors.expense : AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        exceededBudgets.isNotEmpty
                            ? 'Warning: You have exceeded budget for ${exceededBudgets.map((b) => b.title).join(", ")}!'
                            : 'Attention: ${warningBudgets.map((b) => b.title).join(", ")} approaching spending limit (85%+)!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: exceededBudgets.isNotEmpty ? AppColors.expense : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category Budgets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => _showSetCategoryBudgetModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Limit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // List of category budget progress bars with tap to edit
            if (activeBudgets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text(
                      'No category budgets set yet',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick any of your categories and set a monthly spending limit.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => _showSetCategoryBudgetModal(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Set First Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else
              ...activeBudgets.map((b) => GestureDetector(
                    onTap: () => _showAdjustBudgetModal(context, b),
                    child: BudgetProgressBar(budget: b),
                  )),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
