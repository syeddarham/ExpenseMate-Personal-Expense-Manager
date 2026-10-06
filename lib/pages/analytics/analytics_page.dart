import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Screen 05: Analytics & Financial Insights with Interactive Charts
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedFilterIndex = 2; // Default to 'Month'
  final List<String> _filters = ['Day', 'Week', 'Month', 'Year'];
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final filteredExpenses = _getFilteredExpenses(expenseState.transactions);
    final categorySpending = _getCategorySpending(filteredExpenses);
    final totalExpense = _getTotalExpense(filteredExpenses);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Financial Analytics', showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Filter Tabs
            _buildTimeFilterTabs(),
            const SizedBox(height: AppSpacing.lg),

            // Spending Summary Card with Donut Chart
            _buildChartCard(categorySpending, totalExpense),
            const SizedBox(height: AppSpacing.lg),

            // Dynamic Trend Bar Chart
            _buildTrendBarChartCard(filteredExpenses, expenseState.currencySymbol),
            const SizedBox(height: AppSpacing.lg),

            // Category Breakdown List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${categorySpending.length} Categories',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Category List
            if (categorySpending.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No expense transactions recorded yet.'),
                ),
              )
            else
              ...categorySpending.entries.map((entry) {
                final cat = entry.key;
                final amt = entry.value;
                final pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;

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
                          color: cat.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${pct.toStringAsFixed(1)}% of total',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        AppHelpers.formatCurrency(amt),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: isSelected ? AppShadows.card : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartCard(Map<TransactionCategory, double> categorySpending, double totalExpense) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spending Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(
                'Total: ${AppHelpers.formatCurrency(totalExpense)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (categorySpending.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No spending data available')),
            )
          else
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 55,
                      sections: _generatePieSections(categorySpending, totalExpense),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        AppHelpers.formatCurrency(totalExpense),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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

  List<PieChartSectionData> _generatePieSections(
      Map<TransactionCategory, double> categorySpending, double totalExpense) {
    int i = 0;
    return categorySpending.entries.map((entry) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 45.0 : 35.0;
      final fontSize = isTouched ? 14.0 : 11.0;
      final cat = entry.key;
      final amt = entry.value;
      final pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;
      i++;

      return PieChartSectionData(
        color: cat.color,
        value: amt,
        title: '${pct.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<FinancialTransaction> _getFilteredExpenses(List<FinancialTransaction> allTransactions) {
    final now = DateTime.now();
    return allTransactions.where((tx) {
      if (!tx.isExpense) return false;
      final d = tx.date;
      switch (_selectedFilterIndex) {
        case 0: // Day (Today)
          return d.year == now.year && d.month == now.month && d.day == now.day;
        case 1: // Week (Monday of this week through Sunday)
          final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          final nextMonday = monday.add(const Duration(days: 7));
          return !d.isBefore(monday) && d.isBefore(nextMonday);
        case 2: // Month (Current month)
          return d.year == now.year && d.month == now.month;
        case 3: // Year (Current year)
          return d.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Map<TransactionCategory, double> _getCategorySpending(List<FinancialTransaction> filteredTx) {
    final Map<TransactionCategory, double> map = {};
    for (final tx in filteredTx) {
      final existingCat = map.keys.firstWhere(
        (c) => c.id == tx.category.id,
        orElse: () => tx.category,
      );
      map[existingCat] = (map[existingCat] ?? 0.0) + tx.amount;
    }
    return map;
  }

  double _getTotalExpense(List<FinancialTransaction> filteredTx) {
    return filteredTx.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  String get _trendTitle {
    switch (_selectedFilterIndex) {
      case 0:
        return "Today's Spending Trend";
      case 1:
        return 'Weekly Spending Trend';
      case 2:
        return 'Monthly Spending Trend';
      case 3:
        return 'Yearly Spending Trend';
      default:
        return 'Spending Trend';
    }
  }

  _TrendResult _computeTrendData(List<FinancialTransaction> expenses) {
    if (_selectedFilterIndex == 0) {
      // Day (Today): 6 time blocks: 12am (0-3), 4am (4-7), 8am (8-11), 12pm (12-15), 4pm (16-19), 8pm (20-23)
      final labels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];
      final values = List<double>.filled(6, 0.0);
      for (final tx in expenses) {
        final bucket = (tx.date.hour ~/ 4).clamp(0, 5);
        values[bucket] += tx.amount;
      }
      return _TrendResult(labels, values);
    } else if (_selectedFilterIndex == 1) {
      // Week: Mon - Sun (7 days)
      final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final values = List<double>.filled(7, 0.0);
      for (final tx in expenses) {
        final dayIndex = (tx.date.weekday - 1).clamp(0, 6);
        values[dayIndex] += tx.amount;
      }
      return _TrendResult(labels, values);
    } else if (_selectedFilterIndex == 2) {
      // Month: Weeks of month (W1: 1-7, W2: 8-14, W3: 15-21, W4: 22-28, W5: 29-31)
      final labels = ['W1', 'W2', 'W3', 'W4', 'W5'];
      final values = List<double>.filled(5, 0.0);
      for (final tx in expenses) {
        final day = tx.date.day;
        int bucket = (day - 1) ~/ 7;
        if (bucket > 4) bucket = 4;
        values[bucket] += tx.amount;
      }
      return _TrendResult(labels, values);
    } else {
      // Year: 12 months (Jan - Dec)
      final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final values = List<double>.filled(12, 0.0);
      for (final tx in expenses) {
        final mIndex = (tx.date.month - 1).clamp(0, 11);
        values[mIndex] += tx.amount;
      }
      return _TrendResult(labels, values);
    }
  }

  Widget _buildTrendBarChartCard(List<FinancialTransaction> filteredExpenses, String currencySymbol) {
    final trendData = _computeTrendData(filteredExpenses);
    final labels = trendData.labels;
    final values = trendData.values;
    final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? (maxVal * 1.3).ceilToDouble() : 100.0;
    final barWidth = _selectedFilterIndex == 3 ? 8.0 : (_selectedFilterIndex == 0 ? 16.0 : 14.0);

    return Container(
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
              Text(_trendTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(
                'Total: ${AppHelpers.formatCurrency(values.fold(0.0, (s, v) => s + v))}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = groupIndex < labels.length ? labels[groupIndex] : '';
                      return BarTooltipItem(
                        '$label\n${AppHelpers.formatCurrency(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(values.length, (i) {
                  return _makeBarGroup(i, values[i], maxY, barWidth);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, double maxY, double barWidth) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: AppColors.border.withAlpha(60),
          ),
        ),
      ],
    );
  }
}

class _TrendResult {
  final List<String> labels;
  final List<double> values;
  const _TrendResult(this.labels, this.values);
}
