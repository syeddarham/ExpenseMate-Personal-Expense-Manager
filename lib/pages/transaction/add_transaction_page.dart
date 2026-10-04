import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../scan/scan_screen.dart';

/// Screen 03: Add Transaction (Expense & Income Logging)
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  TransactionType _selectedType = TransactionType.expense;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionCategory _selectedCategory;
  String _selectedAccount = 'Debit Card';
  DateTime _selectedDate = DateTime.now();

  final List<String> _accounts = ['Cash', 'Debit Card', 'Credit Card', 'Bank Account', 'Digital Wallet'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = TransactionCategory.defaultCategories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty ? _selectedCategory.name : _titleController.text.trim();

    final newTx = FinancialTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      account: _selectedAccount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.pop(context, newTx);
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = TransactionCategory.defaultCategories.where((cat) {
      return _selectedType == TransactionType.expense ? cat.isExpense : !cat.isExpense;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Add Transaction'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income vs Expense Segmented Switch
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Amount Input Card
            _buildAmountCard(),
            const SizedBox(height: AppSpacing.lg),

            // Title / Merchant
            CustomTextField(
              label: 'Title or Merchant',
              hint: 'e.g. Starbucks Coffee, Walmart, Monthly Rent',
              controller: _titleController,
              prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category Selection
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildCategoryGrid(availableCategories),
            const SizedBox(height: AppSpacing.md),

            // Account & Date Selection Row
            Row(
              children: [
                Expanded(child: _buildAccountDropdown()),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildDatePicker()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Note
            CustomTextField(
              label: 'NOTE',
              hint: 'e.g. Dinner, Monthly subscription',
              controller: _noteController,
              prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Add Receipt Attachment (from Figma Screen 20)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryDark, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('Optional · JPG, PNG or PDF', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Transaction Button
            CustomButton(
              label: 'Save transaction',
              icon: Icons.check_circle_outline,
              onPressed: _saveTransaction,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.expense;
                  _selectedCategory = TransactionCategory.defaultCategories[0];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _selectedType == TransactionType.expense ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.income;
                  _selectedCategory = TransactionCategory.defaultCategories[6];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _selectedType == TransactionType.income ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amount', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Row(
            children: [
              Text(
                Provider.of<ExpenseState>(context).currencySymbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<TransactionCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = _selectedCategory.id == cat.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withAlpha(30) : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? cat.color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, color: cat.color, size: 24),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAccount,
              isExpanded: true,
              items: _accounts
                  .map((acc) => DropdownMenuItem(value: acc, child: Text(acc, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedAccount = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppHelpers.formatDate(_selectedDate), style: const TextStyle(fontSize: 13)),
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
