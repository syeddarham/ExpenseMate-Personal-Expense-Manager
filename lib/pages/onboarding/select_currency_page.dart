import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/custom_button.dart';
import '../../services/api_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/currencies_data.dart';
import '../home/home_page.dart';

/// Screen 15: 15_Select Currency
class SelectCurrencyPage extends StatefulWidget {
  final String country;
  const SelectCurrencyPage({super.key, this.country = 'United States'});

  @override
  State<SelectCurrencyPage> createState() => _SelectCurrencyPageState();
}

class _SelectCurrencyPageState extends State<SelectCurrencyPage> {
  String _selectedCode = 'USD';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _currencies = AppCurrencies.all;

  List<Map<String, String>> get _displayedCurrencies {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _currencies;
    return _currencies.where((c) {
      return c['code']!.toLowerCase().contains(q) || c['name']!.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your Currency',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Choose your preferred base currency for transactions and analytics.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search currency or code...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Currency List
              Expanded(
                child: ListView.separated(
                  itemCount: _displayedCurrencies.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final curr = _displayedCurrencies[index];
                    final isSelected = _selectedCode == curr['code'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCode = curr['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight.withAlpha(50) : Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withAlpha(25) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                curr['flag'] ?? '🌐',
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        curr['code']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          curr['symbol'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    curr['name']!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                            else
                              const Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Get Started Button
              CustomButton(
                label: 'Get Started',
                onPressed: () {
                  final chosen = _currencies.firstWhere((c) => c['code'] == _selectedCode);
                  expenseState.setCurrency(chosen['symbol']!, chosen['code']!);
                  if (ApiService.hasToken) {
                    ApiService.updateMe(
                      country: widget.country,
                      currencyCode: chosen['code'],
                      currencySymbol: chosen['symbol'],
                    );
                  }
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
