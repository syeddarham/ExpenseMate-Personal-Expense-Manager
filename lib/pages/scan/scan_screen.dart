import 'package:flutter/material.dart';
import '../../components/app_bar.dart';
import '../../utils/constants.dart';

/// Screen 19: 19_Scan Screen
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int _selectedTabIndex = 1; // 0: QR, 1: Expense, 2: Bill
  final List<String> _tabs = ['QR', 'Expense', 'Bill'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Scan',
        showBack: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Viewfinder background simulation
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Scanning…',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  // Corner target indicators
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls and Mode Selector
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Mode selector pills from Figma (QR, Expense, Bill)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_tabs.length, (idx) {
                      final isSelected = _selectedTabIndex == idx;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            _tabs[idx],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),

                // Shutter button & gallery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Receipt scanned successfully! Extracted \$46.80 for Food & Dining.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
