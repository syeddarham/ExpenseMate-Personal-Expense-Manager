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
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final transactions = expenseState.transactions;
    final totalExpense = expenseState.totalExpense;

    final now = DateTime.now();
    final monthTitle = '${_monthNames[now.month - 1]}, ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CustomAppBar(title: monthTitle, showBack: true),
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
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Text(
                          'Tracked',
                          style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppHelpers.formatCurrency(totalExpense),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        fontFamilyFallback: ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Line Chart for Spending Trend
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
                                const labels = ['W1', 'W2', 'W3', 'W4', 'W5'];
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
                            spots: _generateSpots(transactions, true),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withAlpha(40),
                            ),
                          ),
                          LineChartBarData(
                            spots: _generateSpots(transactions, false),
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

            // Dynamic transactions list
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No transaction history yet',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: transactions.take(10).map((tx) {
                  return _buildHistoryItem(
                    tx.title,
                    '${tx.category.name} • ${tx.account}',
                    tx.amount,
                    !tx.isExpense,
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<dynamic> transactions, bool isPrimary) {
    if (transactions.isEmpty) {
      return const [
        FlSpot(0, 0),
        FlSpot(1, 0),
        FlSpot(2, 0),
        FlSpot(3, 0),
        FlSpot(4, 0),
      ];
    }
    if (isPrimary) {
      return const [
        FlSpot(0, 20),
        FlSpot(1, 45),
        FlSpot(2, 35),
        FlSpot(3, 80),
        FlSpot(4, 65),
      ];
    } else {
      return const [
        FlSpot(0, 10),
        FlSpot(1, 25),
        FlSpot(2, 20),
        FlSpot(3, 50),
        FlSpot(4, 40),
      ];
    }
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
              fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial'],
            ),
          ),
        ],
      ),
    );
  }
}
