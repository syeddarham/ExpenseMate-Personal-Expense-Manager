import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/currencies_data.dart';
import '../category/categories_page.dart';
import '../login/login_page.dart';

/// Screen 06: Profile & Account Settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _biometricEnabled = true;

  void _showCurrencyDialog(BuildContext context, ExpenseState expenseState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final all = AppCurrencies.all;
            final q = searchQuery.toLowerCase().trim();
            final filtered = q.isEmpty
                ? all
                : all.where((c) {
                    final cCode = (c['code'] ?? '').toLowerCase();
                    final cName = (c['name'] ?? '').toLowerCase();
                    final cSymbol = (c['symbol'] ?? '').toLowerCase();
                    return cCode.contains(q) || cName.contains(q) || cSymbol.contains(q);
                  }).toList();

            final String activeCode = () {
              try {
                return expenseState.currencyCode.toUpperCase();
              } catch (_) {
                return 'USD';
              }
            }();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Select Currency',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Choose a currency for your accounts, transactions, and budgets.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency or code...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (cContext, idx) {
                        final curr = filtered[idx];
                        final code = curr['code'] ?? 'USD';
                        final symbol = curr['symbol'] ?? '\$';
                        final name = curr['name'] ?? '';
                        final isSelected = activeCode == code.toUpperCase();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight.withAlpha(50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
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
                            title: Row(
                              children: [
                                Text(
                                  code,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
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
                                    symbol,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.primary),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              if (isSelected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Your account is already set to $code ($symbol).'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                                return;
                              }
                              _showConversionPromptDialog(context, expenseState, {
                                'code': code,
                                'symbol': symbol,
                                'name': name,
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConversionPromptDialog(
    BuildContext context,
    ExpenseState expenseState,
    Map<String, String> targetCurrency,
  ) {
    String fromCode = 'USD';
    String fromSymbol = '\$';
    try {
      fromCode = expenseState.currencyCode;
    } catch (_) {}
    try {
      fromSymbol = expenseState.currencySymbol;
    } catch (_) {}
    final toCode = targetCurrency['code'] ?? 'USD';
    final toSymbol = targetCurrency['symbol'] ?? '\$';

    if (fromCode.toUpperCase() == toCode.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your account is already set to $toCode ($toSymbol).'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        double? exchangeRate;
        bool isLoadingRate = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            if (isLoadingRate && exchangeRate == null && errorMessage == null) {
              CurrencyService.getExchangeRate(fromCode, toCode).then((rate) {
                if (dlgCtx.mounted) {
                  setDlgState(() {
                    isLoadingRate = false;
                    exchangeRate = rate;
                    if (rate == null) {
                      errorMessage = 'Could not fetch live rate. You can still switch currency.';
                    }
                  });
                }
              }).catchError((_) {
                if (dlgCtx.mounted) {
                  setDlgState(() {
                    isLoadingRate = false;
                    errorMessage = 'Network error fetching rate.';
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Change Currency',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switching from $fromCode ($fromSymbol) to $toCode ($toSymbol)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Live Exchange Rate Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isLoadingRate
                          ? const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Fetching live exchange rate...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            )
                          : (exchangeRate != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_up, color: AppColors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Live Rate: 1 $fromCode = ${exchangeRate!.toStringAsFixed(4)} $toCode',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Example: If you had $fromSymbol 1.00 in your account:\n'
                                      '• Converted: $toSymbol ${(1.0 * exchangeRate!).toStringAsFixed(2)}\n'
                                      '• Stay Same Amount: $toSymbol 1.00',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  ],
                                )
                              : Text(
                                  errorMessage ?? 'Live rate unavailable',
                                  style: const TextStyle(fontSize: 12, color: AppColors.expense),
                                )),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const Text(
                      'How would you like to handle your existing balances, transactions, and budgets?',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              actions: [
                // 1. Convert Amounts
                if (exchangeRate != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: () async {
                      Navigator.pop(dlgCtx);
                      final success = await expenseState.changeCurrencyWithConversion(
                        newCode: toCode,
                        newSymbol: toSymbol,
                        convertAmounts: true,
                        rate: exchangeRate!,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Converted all amounts to $toCode ($toSymbol) at 1 $fromCode = ${exchangeRate!.toStringAsFixed(2)} $toCode'
                                  : 'Currency updated to $toCode',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    child: Text('Convert Amounts to $toCode (Live Rate)'),
                  ),
                const SizedBox(height: 6),

                // 2. Stay Same Amount
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: () async {
                    Navigator.pop(dlgCtx);
                    await expenseState.changeCurrencyWithConversion(
                      newCode: toCode,
                      newSymbol: toSymbol,
                      convertAmounts: false,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched currency to $toCode ($toSymbol) without converting figures.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  child: Text('Stay Same Amount in $toCode'),
                ),
                const SizedBox(height: 4),

                // 3. Cancel
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Center(
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final isDark = expenseState.isDarkMode;
    final currentUser = AuthService().currentUser;
    final userName = currentUser?.name.isNotEmpty == true ? currentUser!.name : 'ExpenseMate User';
    final userEmail = currentUser?.email.isNotEmpty == true ? currentUser!.email : 'user@expensemate.com';

    // Initials for avatar
    final initials = userName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: const CustomAppBar(title: 'Profile & Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials.isNotEmpty ? initials : 'EM',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),



            // Preferences Group
            _buildSectionHeader('Preferences'),
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              value: _biometricEnabled,
              isDark: isDark,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme',
              value: isDark,
              isDark: isDark,
              onChanged: (val) => expenseState.toggleTheme(val),
            ),
            _buildSettingsTile(
              icon: Icons.monetization_on_outlined,
              title: 'Preferred Currency',
              subtitle: () {
                String c = 'USD';
                String s = '\$';
                try {
                  c = expenseState.currencyCode;
                } catch (_) {}
                try {
                  s = expenseState.currencySymbol;
                } catch (_) {}
                return '$c ($s) • Tap to change';
              }(),
              isDark: isDark,
              onTap: () => _showCurrencyDialog(context, expenseState),
            ),
            _buildSettingsTile(
              icon: Icons.category_outlined,
              title: 'Manage Categories',
              subtitle: '${expenseState.categories.length} categories • Add, edit, or delete',
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Export & Data Group
            _buildSectionHeader('Data & Security'),
            _buildSettingsTile(
              icon: Icons.file_download_outlined,
              title: 'Export Transactions (CSV / PDF)',
              subtitle: 'Download complete report',
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating CSV/PDF financial export...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Log Out Button
            OutlinedButton.icon(
              onPressed: () {
                AuthService().logout();
                expenseState.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.expense, size: 18),
              label: const Text('Log Out', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expense),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
