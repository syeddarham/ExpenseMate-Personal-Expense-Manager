import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../utils/constants.dart';
import 'email_verification_page.dart';

/// Screen 06 & 07: 06_Sign up / 07_Sign up Filled
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms of Service & Privacy Policy'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationPage(email: _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Start your journey toward smarter money management.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Email
                CustomTextField(
                  label: 'Email Address',
                  hint: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter email' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Password
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => (v != null && v.length < 6) ? 'At least 6 characters' : null,
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
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Terms agreement
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _agreeToTerms = val ?? true),
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to the Terms of Service and Privacy Policy',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sign Up Button
                CustomButton(
                  label: 'Sign Up',
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
