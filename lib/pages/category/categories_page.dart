import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../models/category.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Expense, 2 = Income
  String _searchQuery = '';

  void _showCategoryDialog({TransactionCategory? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: isEditing ? categoryToEdit.name : '');
    bool isExpense = isEditing ? categoryToEdit.isExpense : true;
    String selectedIcon = isEditing ? categoryToEdit.iconName : 'restaurant';
    Color selectedColor = isEditing ? categoryToEdit.color : TransactionCategory.availableColors[0];
    bool isSaving = false;
    String? errorMessage;

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
            final colorHex = AppColors.toHex(selectedColor);

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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Category' : 'New Category',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Live Preview Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: selectedColor.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameController.text.trim().isEmpty ? 'Category Preview' : nameController.text.trim(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isExpense ? 'Expense Category' : 'Income Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isExpense ? AppColors.expense : AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.expense),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.expense, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Category Name Field
                    CustomTextField(
                      label: 'Category Name',
                      hint: 'e.g., Coffee, Pet Care, Freelance',
                      controller: nameController,
                      prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Type Toggle (Expense vs Income)
                    const Text('Category Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isExpense = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isExpense ? AppColors.expense : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    color: isExpense ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isExpense = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !isExpense ? AppColors.income : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    color: !isExpense ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Icon Selector
                    const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: TransactionCategory.availableIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
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
                                border: Border.all(
                                  color: isSelected ? selectedColor : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? selectedColor : AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Color Selector
                    const Text('Select Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TransactionCategory.availableColors.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final c = TransactionCategory.availableColors[i];
                          final isSelected = selectedColor == c;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black87 : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: c.withAlpha(120), blurRadius: 6, spreadRadius: 1)]
                                    : null,
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button
                    CustomButton(
                      label: isEditing ? 'Update Category' : 'Create Category',
                      isLoading: isSaving,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setModalState(() => errorMessage = 'Please enter a category name');
                          return;
                        }

                        setModalState(() {
                          isSaving = true;
                          errorMessage = null;
                        });

                        final expenseState = Provider.of<ExpenseState>(context, listen: false);

                        if (isEditing) {
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await expenseState.editCategory(
                            id: categoryToEdit.id,
                            name: name,
                            icon: selectedIcon,
                            color: colorHex,
                            isExpense: isExpense,
                          );
                          if (!mounted) return;
                          if (success) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Category "$name" updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            setModalState(() {
                              isSaving = false;
                              errorMessage = 'Could not update category. Name may be duplicate.';
                            });
                          }
                        } else {
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final newCat = await expenseState.addCategory(
                            name: name,
                            icon: selectedIcon,
                            color: colorHex,
                            isExpense: isExpense,
                          );
                          if (!mounted) return;
                          if (newCat != null) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Category "$name" created successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            setModalState(() {
                              isSaving = false;
                              errorMessage = 'Could not create category. A category with this name might already exist.';
                            });
                          }
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

  void _confirmDeleteCategory(BuildContext context, TransactionCategory category) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.expense, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text('Delete Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}"?\n\n'
            'Note: You cannot delete a category if it has active transactions logged under it.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final expenseState = Provider.of<ExpenseState>(context, listen: false);
                final res = await expenseState.deleteCategory(category.id);
                if (!mounted) return;
                if (res.success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Category "${category.name}" deleted.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Cannot delete this category.'),
                      backgroundColor: AppColors.expense,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final categories = expenseState.categories;

    // Filter categories
    final filtered = categories.where((c) {
      if (_selectedFilterIndex == 1 && !c.isExpense) return false;
      if (_selectedFilterIndex == 2 && c.isExpense) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Manage Categories',
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            tooltip: 'Add Category',
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_page_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Category', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: [
                // Search box
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All (${categories.length})', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expenses (${categories.where((c) => c.isExpense).length})', 1),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income (${categories.where((c) => !c.isExpense).length})', 2),
                  ],
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category_outlined, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No categories found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap + to create a custom category.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => _showCategoryDialog(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      final isCatBudgeted = expenseState.budgets.any((b) => b.category.id == cat.id && b.limitAmount > 0);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: [
                            // Leading icon badge with custom color
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cat.color.withAlpha(35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 22),
                            ),
                            const SizedBox(width: 14),

                            // Name & Badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cat.isExpense ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.isExpense ? 'Expense' : 'Income',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: cat.isExpense ? AppColors.expense : AppColors.income,
                                          ),
                                        ),
                                      ),
                                      if (isCatBudgeted) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Budgeted',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions: Edit and Delete
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                              tooltip: 'Edit Category',
                              onPressed: () => _showCategoryDialog(categoryToEdit: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
                              tooltip: 'Delete Category',
                              onPressed: () => _confirmDeleteCategory(context, cat),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
