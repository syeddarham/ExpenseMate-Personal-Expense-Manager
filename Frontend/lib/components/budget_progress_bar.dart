import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class BudgetProgressBar extends StatelessWidget {
  final Budget budget;

  const BudgetProgressBar({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (budget.isExceeded) {
      statusColor = AppColors.expense;
    } else if (budget.isNearLimit) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.primary;
    }

    final percentageText = (budget.progressPercentage * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: budget.category.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(budget.category.icon, size: 20, color: budget.category.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  budget.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                '$percentageText%',
                style: TextStyle(fontWeight: FontWeight.w700, color: statusColor, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: budget.progressPercentage,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${AppHelpers.formatCurrency(budget.spentAmount)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Limit: ${AppHelpers.formatCurrency(budget.limitAmount)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
