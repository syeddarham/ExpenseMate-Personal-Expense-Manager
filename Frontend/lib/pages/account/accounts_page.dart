import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../models/account.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  static const List<Map<String, dynamic>> _accountTypes = [
    {'type': 'cash', 'label': 'Cash', 'icon': Icons.payments_outlined},
    {'type': 'bank', 'label': 'Bank Account', 'icon': Icons.account_balance_outlined},
    {'type': 'card', 'label': 'Card', 'icon': Icons.credit_card_outlined},
    {'type': 'wallet', 'label': 'Digital Wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'cash':
      default:
        return Icons.payments_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return const Color(0xFF2563EB); // Royal Blue
      case 'card':
        return const Color(0xFF7C3AED); // Deep Violet
      case 'wallet':
        return const Color(0xFFEA580C); // Sunset Orange
      case 'cash':
      default:
        return const Color(0xFF059669); // Emerald Green
    }
  }

  void _showAddEditAccountModal({Account? account}) {
    final expenseState = Provider.of<ExpenseState>(context, listen: false);
    final isEditing = account != null;

    final nameController = TextEditingController(text: account?.name ?? '');
    final openingController = TextEditingController(
      text: account != null ? account.openingBalance.toStringAsFixed(2) : '0.00',
    );
    String selectedType = account?.type ?? 'cash';
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Financial Account' : 'Add Financial Account',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (errorText != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),

                    // Account Name
                    CustomTextField(
                      label: 'ACCOUNT NAME',
                      hint: 'e.g. Chase Checking, Personal Cash, Apple Pay',
                      controller: nameController,
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Account Type Selection
                    const Text('ACCOUNT TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _accountTypes.map((t) {
                        final isSel = selectedType == t['type'];
                        final color = _colorForType(t['type']);
                        return ChoiceChip(
                          selected: isSel,
                          avatar: Icon(t['icon'] as IconData, size: 16, color: isSel ? Colors.white : color),
                          label: Text(
                            t['label'] as String,
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selectedColor: color,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? color : AppColors.border),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = t['type']);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Opening Balance
                    CustomTextField(
                      label: 'OPENING BALANCE',
                      hint: '0.00',
                      controller: openingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: Text(
                          expenseState.currencySymbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    CustomButton(
                      label: isEditing ? 'Update Account' : 'Save Account',
                      isLoading: isSaving,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setModalState(() => errorText = 'Please enter an account name.');
                          return;
                        }

                        final opening = double.tryParse(openingController.text.trim()) ?? 0.0;
                        setModalState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        if (isEditing) {
                          final res = await expenseState.updateAccount(
                            id: account.id,
                            name: name,
                            type: selectedType,
                            openingBalance: opening,
                          );
                          if (!mounted) return;
                          if (res != null) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Account "$name" updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            setModalState(() {
                              isSaving = false;
                              errorText = 'Failed to update account. Check connection or name duplicates.';
                            });
                          }
                        } else {
                          final res = await expenseState.addAccount(
                            name: name,
                            type: selectedType,
                            openingBalance: opening,
                          );
                          if (!mounted) return;
                          if (res != null) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Account "$name" created successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            setModalState(() {
                              isSaving = false;
                              errorText = 'Failed to create account. Check connection or name duplicates.';
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(Account account) {
    final expenseState = Provider.of<ExpenseState>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\nTransactions associated with this account may need to be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await expenseState.deleteAccount(account.id);
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Account "${account.name}" deleted.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete account. It may have existing transactions.'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final accounts = expenseState.accounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Manage Accounts',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
            tooltip: 'Add Account',
            onPressed: () => _showAddEditAccountModal(),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'No Financial Accounts Found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create custom accounts such as Cash, Bank, Credit Card, or Digital Wallets to track your balances.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomButton(
                      label: 'Add First Account',
                      onPressed: () => _showAddEditAccountModal(),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final acc = accounts[index];
                final color = _colorForType(acc.type);
                final icon = _iconForType(acc.type);

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    acc.type.toUpperCase(),
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Opening: ${AppHelpers.formatCurrency(acc.openingBalance)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppHelpers.formatCurrency(acc.balance),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: acc.balance >= 0 ? AppColors.textPrimary : AppColors.expense,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                onPressed: () => _showAddEditAccountModal(account: acc),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                                onPressed: () => _confirmDeleteAccount(acc),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CustomButton(
            label: '+ Add New Account',
            onPressed: () => _showAddEditAccountModal(),
          ),
        ),
      ),
    );
  }
}
