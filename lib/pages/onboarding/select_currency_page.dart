import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/custom_button.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
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

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'BDT', 'symbol': '৳', 'name': 'Bangladeshi Taka'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  ];

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
              const SizedBox(height: AppSpacing.lg),

              // Currency List
              Expanded(
                child: ListView.separated(
                  itemCount: _currencies.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final curr = _currencies[index];
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
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.border.withAlpha(60),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                curr['symbol']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    curr['code']!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
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
                  expenseState.setCurrency(chosen['symbol']!);
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
