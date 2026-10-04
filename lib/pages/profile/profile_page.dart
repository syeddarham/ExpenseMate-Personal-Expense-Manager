import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../services/auth_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
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
    final currencies = [
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'PKR', 'symbol': '₨', 'name': 'Pakistani Rupee'},
      {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
      {'code': 'CAD', 'symbol': '\$', 'name': 'Canadian Dollar'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              final isSelected = expenseState.currencySymbol == c['symbol'];
              return ListTile(
                title: Text('${c['name']} (${c['code']})'),
                leading: Text(c['symbol']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  expenseState.setCurrency(c['symbol']!);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final isDark = expenseState.isDarkMode;

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
                    child: const Text(
                      'SA',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syed Arham',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'k242551@nu.edu.pk',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Financial Accounts Group
            _buildSectionHeader('Financial Accounts'),
            _buildSettingsTile(
              icon: Icons.account_balance_rounded,
              title: 'Bank Accounts',
              subtitle: '2 Connected accounts',
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.credit_card_rounded,
              title: 'Cards & Wallets',
              subtitle: 'Visa •••• 4821, Apple Pay',
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),

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
              subtitle: 'Current Symbol: ${expenseState.currencySymbol}',
              isDark: isDark,
              onTap: () => _showCurrencyDialog(context, expenseState),
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
