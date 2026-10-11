import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TransactionCard extends StatelessWidget {
  final FinancialTransaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final amountPrefix = isExpense ? '-' : '+';
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: transaction.category.color.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            transaction.category.icon,
            color: transaction.category.color,
            size: 22,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${transaction.account} • ${AppHelpers.formatFriendlyDate(transaction.date)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          '$amountPrefix${AppHelpers.formatCurrency(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: amountColor,
          ),
        ),
      ),
    );
  }
}
