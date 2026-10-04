import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../utils/constants.dart';
import 'password_reset_success_page.dart';

/// Screen 11 & 12: 11_Reset Password Empty / 12_Reset Password Filled
class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, this.email = ''});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PasswordResetSuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUpperLower = password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
    final hasNumberSymbol = password.contains(RegExp(r'[0-9]')) && password.contains(RegExp(r'[^A-Za-z0-9]'));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Create New Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Your new password should be different from your previous password.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Password
              CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Confirm Password
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Strong Password Criteria Box
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Strong Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildRequirementRow('Minimum 8 character', hasMinLength),
                    _buildRequirementRow('Uppercase and lowercase character', hasUpperLower),
                    _buildRequirementRow('Minimum 1 number and symbol', hasNumberSymbol),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Reset Password Button
              CustomButton(
                label: 'Reset Password',
                onPressed: _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
