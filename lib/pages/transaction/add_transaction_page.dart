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
import '../category/categories_page.dart';
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

  TransactionCategory? _selectedCategory;
  String _selectedAccount = 'Debit Card';
  DateTime _selectedDate = DateTime.now();

  final List<String> _accounts = ['Cash', 'Debit Card', 'Credit Card', 'Bank Account', 'Digital Wallet'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showQuickAddCategoryModal() {
    final nameController = TextEditingController();
    String selectedIcon = 'restaurant';
    Color selectedColor = TransactionCategory.availableColors[0];
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
            final iconData = TransactionCategory.parseIconName(selectedIcon);
            final colorHex = '#${(selectedColor.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

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
                          'Add ${_selectedType == TransactionType.expense ? "Expense" : "Income"} Category',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Preview
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: selectedColor.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: selectedColor,
                            radius: 18,
                            child: Icon(iconData, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nameController.text.trim().isEmpty ? 'Category Name' : nameController.text.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (errorText != null) ...[
                      Text(errorText!, style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    CustomTextField(
                      label: 'Category Name',
                      hint: 'e.g. Subscriptions, Groceries, Bonus',
                      controller: nameController,
                      prefixIcon: Icon(Icons.label_outline, color: AppColors.primary),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Icon selector
                    const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 90,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: TransactionCategory.availableIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (ctx, i) {
                          final item = TransactionCategory.availableIcons[i];
                          final iconName = item['name'] as String;
                          final icon = item['icon'] as IconData;
                          final isSelected = selectedIcon == iconName;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIcon = iconName),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor.withAlpha(40) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: isSelected ? selectedColor : AppColors.border, width: isSelected ? 2 : 1),
                              ),
                              child: Icon(icon, color: isSelected ? selectedColor : AppColors.textSecondary, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Color selector
                    const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TransactionCategory.availableColors.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final c = TransactionCategory.availableColors[i];
                          final isSelected = selectedColor.toARGB32() == c.toARGB32();
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Colors.black87 : Colors.transparent, width: 2),
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    CustomButton(
                      label: 'Add Category',
                      isLoading: isSaving,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setModalState(() => errorText = 'Please enter a category name');
                          return;
                        }

                        setModalState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        final nav = Navigator.of(ctx);
                        final expenseState = Provider.of<ExpenseState>(context, listen: false);
                        final newCat = await expenseState.addCategory(
                          name: name,
                          icon: selectedIcon,
                          color: colorHex,
                          isExpense: _selectedType == TransactionType.expense,
                        );

                        if (!mounted) return;
                        if (newCat != null) {
                          setState(() {
                            _selectedCategory = newCat;
                          });
                          nav.pop();
                        } else {
                          setModalState(() {
                            isSaving = false;
                            errorText = 'Could not create category. Name may already exist.';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

    final expenseState = Provider.of<ExpenseState>(context, listen: false);
    final availableCategories = expenseState.categories.where((cat) {
      return _selectedType == TransactionType.expense ? cat.isExpense : !cat.isExpense;
    }).toList();

    final category = _selectedCategory ??
        (availableCategories.isNotEmpty
            ? availableCategories.first
            : TransactionCategory.defaultCategories.first);

    final title = _titleController.text.trim().isEmpty ? category.name : _titleController.text.trim();

    final newTx = FinancialTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: _selectedType,
      category: category,
      date: _selectedDate,
      account: _selectedAccount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.pop(context, newTx);
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final availableCategories = expenseState.categories.where((cat) {
      return _selectedType == TransactionType.expense ? cat.isExpense : !cat.isExpense;
    }).toList();

    // Ensure _selectedCategory points to an available category of the current type
    if (_selectedCategory == null || !availableCategories.any((c) => c.id == _selectedCategory!.id)) {
      if (availableCategories.isNotEmpty) {
        _selectedCategory = availableCategories.first;
      }
    }

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

            // Category Selection Header with Manage link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  ),
                  child: Text(
                    'Manage Categories',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
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
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
                if (result != null && mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Receipt scan saved: $result'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(128),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Add Receipt / Invoice Attachment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save / Submit Button
            CustomButton(
              label: 'Save Transaction',
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
                  _selectedCategory = null;
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
                  _selectedCategory = null;
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
                  fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
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
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          // "+ Add New" button
          return GestureDetector(
            onTap: _showQuickAddCategoryModal,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withAlpha(120),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    'Add New',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final cat = categories[index];
        final isSelected = _selectedCategory?.id == cat.id;
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
    final expenseState = Provider.of<ExpenseState>(context);
    final accountList = expenseState.accounts.isNotEmpty
        ? expenseState.accounts.map((a) => a.name).toList()
        : _accounts;
    final currentAccount = accountList.contains(_selectedAccount)
        ? _selectedAccount
        : accountList.first;

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
              isExpanded: true,
              value: currentAccount,
              items: accountList.map((acc) {
                return DropdownMenuItem(
                  value: acc,
                  child: Text(acc, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
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
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
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
                Text(
                  AppHelpers.formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 13),
                ),
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
