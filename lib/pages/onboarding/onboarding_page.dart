import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../utils/constants.dart';
import '../auth/auth_page.dart';

/// Screen 02: 02_Onboarding
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              // Hero Illustration Container
              Container(
                height: 260,
                width: 260,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(35),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/dollar.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Title & Subtitle from Figma
              const Text(
                'Take Control of Your Money',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Track your daily expenses, monitor your income, and understand exactly where your money goes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Next Button
              CustomButton(
                label: 'Next',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Terms & Privacy Note
              const Text(
                'By joining you agree to our Terms of Services and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
