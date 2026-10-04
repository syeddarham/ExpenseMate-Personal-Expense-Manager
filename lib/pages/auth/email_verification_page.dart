import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../utils/constants.dart';
import '../onboarding/citizenship_page.dart';

/// Screen 08 & 09: 08_Email Verification / 09_Email Verification Filled
class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({
    super.key,
    this.email = '',
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  int _secondsRemaining = 56;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleVerify() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit code'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CitizenshipPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Email Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "We've sent a 6-digit verification code to:\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6 OTP Digit Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        } else if (val.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Timer / Resend
              if (_secondsRemaining > 0)
                Text(
                  'You can resend the code in $_secondsRemaining seconds',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              else
                TextButton(
                  onPressed: () {
                    setState(() => _secondsRemaining = 56);
                  },
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              // Verify Email Button
              CustomButton(
                label: 'Verify Email',
                onPressed: _handleVerify,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Informational footer
              const Text(
                'Please check your inbox or spam folder for the verification email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
