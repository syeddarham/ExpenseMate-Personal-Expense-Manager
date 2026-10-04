import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../utils/constants.dart';
import 'select_currency_page.dart';

/// Screen 14: 14_Citizenship
class CitizenshipPage extends StatefulWidget {
  const CitizenshipPage({super.key});

  @override
  State<CitizenshipPage> createState() => _CitizenshipPageState();
}

class _CitizenshipPageState extends State<CitizenshipPage> {
  String _selectedCountry = 'United States';

  final List<Map<String, String>> _countries = [
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'Switzerland', 'code': 'CH', 'flag': '🇨🇭'},
    {'name': 'Indonesia', 'code': 'ID', 'flag': '🇮🇩'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'Turkey', 'code': 'TR', 'flag': '🇹🇷'},
    {'name': 'Greece', 'code': 'GR', 'flag': '🇬🇷'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Citizenship', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your Country',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Please select your citizenship or primary residence country.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Country list
              Expanded(
                child: ListView.separated(
                  itemCount: _countries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final isSelected = _selectedCountry == country['name'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCountry = country['name']!),
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
                            Text(country['flag']!, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                country['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
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

              // Continue Button
              CustomButton(
                label: 'Continue',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectCurrencyPage(country: _selectedCountry),
                    ),
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
