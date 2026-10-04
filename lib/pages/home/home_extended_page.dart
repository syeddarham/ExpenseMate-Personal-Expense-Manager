import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Screen 17: 17_HomeScreen-Extended
class HomeExtendedPage extends StatefulWidget {
  const HomeExtendedPage({super.key});

  @override
  State<HomeExtendedPage> createState() => _HomeExtendedPageState();
}

class _HomeExtendedPageState extends State<HomeExtendedPage> {
  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final currency = expenseState.currencySymbol;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: 'July, 2022', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Spend Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Spend',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Text(
                          '-32.3%',
                          style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currency${'3,545.54'}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Line Chart for Spending / Savings
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const labels = ['1K', '3K', '5K', '7K', '10K'];
                                final index = val.toInt();
                                if (index >= 0 && index < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(labels[index], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 20),
                              FlSpot(1, 50),
                              FlSpot(2, 35),
                              FlSpot(3, 90),
                              FlSpot(4, 75),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withAlpha(40),
                            ),
                          ),
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 10),
                              FlSpot(1, 30),
                              FlSpot(2, 25),
                              FlSpot(3, 60),
                              FlSpot(4, 45),
                            ],
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // History Section
            const Text(
              'History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Transactions list from Figma
            _buildHistoryItem('Owen Inc.', 'Revenue', 25.00, true),
            _buildHistoryItem('Nick Inc.', 'Technology Service', 224.00, false),
            _buildHistoryItem('Steve Inc.', 'Marketing Service', 224.00, false),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, double amount, bool isIncome) {
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
              color: isIncome ? AppColors.primaryLight : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.income : AppColors.expense,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : "-"}${AppHelpers.formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
