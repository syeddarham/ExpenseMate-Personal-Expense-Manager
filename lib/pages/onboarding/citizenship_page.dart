import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/countries_data.dart';
import 'select_currency_page.dart';

/// Screen 14: 14_Citizenship
class CitizenshipPage extends StatefulWidget {
  const CitizenshipPage({super.key});

  @override
  State<CitizenshipPage> createState() => _CitizenshipPageState();
}

class _CitizenshipPageState extends State<CitizenshipPage> {
  String _selectedCountry = 'United States';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _countries = AppCountries.all;

  List<Map<String, String>> get _displayedCountries {
    if (_searchQuery.trim().isEmpty) return _countries;
    final q = _searchQuery.toLowerCase().trim();
    return _countries.where((c) {
      final name = c['name']?.toLowerCase() ?? '';
      final code = c['code']?.toLowerCase() ?? '';
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                    hintText: 'Search country or code...',
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

              // Country list
              Expanded(
                child: _displayedCountries.isEmpty
                    ? Center(
                        child: Text(
                          'No country found for "$_searchQuery"',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _displayedCountries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final country = _displayedCountries[index];
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
