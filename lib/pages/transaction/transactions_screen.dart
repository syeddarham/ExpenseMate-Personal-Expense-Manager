import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Screen 18: 18_Transactions Screen
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final PageController _cardPageController = PageController(viewportFraction: 0.9);
  int _currentCardIndex = 0;

  final List<Map<String, String>> _balanceCards = [
    {
      'title': 'My Balance',
      'amount': '\$102,432.43',
      'expiry': '12/28',
      'holder': 'YourName',
      'cardType': 'VISA',
      'color1': '0xFF0F172A',
      'color2': '0xFF334155',
    },
    {
      'title': 'My Balance',
      'amount': '\$87,453.43',
      'expiry': '08/24',
      'holder': 'Your Name',
      'cardType': 'Mastercard',
      'color1': '0xFF059669',
      'color2': '0xFF10B981',
    },
  ];

  final List<Map<String, dynamic>> _lastTransactions = [
    {'title': 'Shopping', 'amount': 350.00, 'isIncome': false, 'icon': Icons.shopping_bag_outlined, 'color': Color(0xFFEC4899)},
    {'title': 'Sent', 'amount': 5435.54, 'isIncome': true, 'icon': Icons.send_rounded, 'color': Color(0xFF10B981)},
    {'title': 'Food & Drinks', 'amount': 432.54, 'isIncome': false, 'icon': Icons.restaurant_rounded, 'color': Color(0xFFF59E0B)},
    {'title': 'Dividend', 'amount': 3350.00, 'isIncome': true, 'icon': Icons.trending_up_rounded, 'color': Color(0xFF06B6D4)},
    {'title': 'Transport', 'amount': 1432.43, 'isIncome': false, 'icon': Icons.directions_car_rounded, 'color': Color(0xFF3B82F6)},
  ];

  @override
  Widget build(BuildContext context) {
    Provider.of<ExpenseState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: 'Transactions', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Card PageView Carousel
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _cardPageController,
                itemCount: _balanceCards.length,
                onPageChanged: (idx) => setState(() => _currentCardIndex = idx),
                itemBuilder: (context, index) {
                  final card = _balanceCards[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(int.parse(card['color1']!)), Color(int.parse(card['color2']!))],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card['title']!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              card['cardType']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 16),
                            ),
                          ],
                        ),
                        Text(
                          card['amount']!,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(card['holder']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(card['expiry']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Carousel dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_balanceCards.length, (idx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentCardIndex == idx ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentCardIndex == idx ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Last Transactions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: const Text(
                'Last Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: _lastTransactions.map((tx) {
                  final isIncome = tx['isIncome'] as bool;
                  final double amt = tx['amount'] as double;
                  final Color color = tx['color'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(tx['icon'] as IconData, color: color, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            tx['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        Text(
                          '${isIncome ? "+" : "-"}${AppHelpers.formatCurrency(amt)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isIncome ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
