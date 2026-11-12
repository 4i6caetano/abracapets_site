import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/finance.dart';


class ExpensesChart extends StatelessWidget {
  const ExpensesChart({super.key, required this.totals});

  final Map<ExpenseCategory, double> totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = ExpenseCategory.values;
    final maxValue = totals.values.fold<double>(0, (m, v) => v > m ? v : m);

    if (maxValue == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Nenhum gasto registrado neste mês',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxValue / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  final c = categories[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Tooltip(
                      message: c.label,
                      child: Column(
                        children: [
                          Icon(c.icon, size: 18, color: c.color),
                          Text(
                            c.label.length > 6
                                ? '${c.label.substring(0, 5)}.'
                                : c.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              tooltipBorderRadius: BorderRadius.circular(10),
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${categories[group.x].label}\n${Fmt.currency(rod.toY)}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < categories.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: totals[categories[i]] ?? 0,
                    width: 22,
                    color: categories[i].color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue * 1.2,
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
