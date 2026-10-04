import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../components/budget_progress_bar.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../models/budget.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
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
                  Text(
                    'Set ${budget.title} Limit',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                label: 'Update Limit',
                onPressed: () {
                  final newLimit = double.tryParse(controller.text.trim());
                  if (newLimit != null && newLimit > 0) {
                    expenseState.setBudgetLimit(budget.category.id, newLimit);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Budget for ${budget.title} updated to \$${newLimit.toStringAsFixed(0)}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final budgets = expenseState.budgets;

    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    // Check for alerts
    final exceededBudgets = budgets.where((b) => b.isExceeded).toList();
    final warningBudgets = budgets.where((b) => b.isNearLimit).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Monthly Budget'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Budget Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category Budgets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  'Tap to adjust',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // List of category budget progress bars with tap to edit
            ...budgets.map((b) => GestureDetector(
                  onTap: () => _showAdjustBudgetModal(context, b),
                  child: BudgetProgressBar(budget: b),
                )),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
