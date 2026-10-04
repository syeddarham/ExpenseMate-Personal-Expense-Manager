import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../utils/constants.dart';
import 'reset_password_page.dart';

/// Screen 10: 10_Forgot Password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendLink() {
    if (_emailController.text.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Forgot Your Password?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                "No worries. Enter your email address and we'll send you a link to reset your password.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Email Address
              CustomTextField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Send Reset Link Button
              CustomButton(
                label: 'Send Reset Link',
                onPressed: _handleSendLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
