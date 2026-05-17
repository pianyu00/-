import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/app_themes.dart';
import '../../utils/strings.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/bounce_tap.dart';

class MonthlySummary {
  final String label;
  final double income;
  final double expense;
  MonthlySummary(this.label, this.income, this.expense);
}

class HomeChartView extends StatelessWidget {
  final List<MonthlySummary> chartData;
  final String currencySymbol;
  final String dateFormat;
  final void Function(String label, String type, double amount) onMonthTap;

  const HomeChartView({
    super.key,
    required this.chartData,
    required this.currencySymbol,
    required this.dateFormat,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                S.t(context, 'no_chart_data'),
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              const SizedBox(height: 4),
              Text(
                S.t(context, 'add_more_chart_hint'),
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxVal = chartData.fold<double>(0, (m, d) {
      final bigger = d.income > d.expense ? d.income : d.expense;
      return bigger > m ? bigger : m;
    });

    double yMax;
    if (maxVal <= 0) {
      yMax = 1000;
    } else {
      final magnitude = pow(10, (log(maxVal) / ln10).floor()).toDouble();
      final stepRaw = maxVal / magnitude / 4;
      final niceStep =
          stepRaw <= 0.5
              ? 0.5
              : stepRaw <= 1
                  ? 1.0
                  : stepRaw <= 2
                      ? 2.0
                      : stepRaw <= 5
                          ? 5.0
                          : 10.0;
      yMax = niceStep * magnitude * 4;
    }

    const yLabelW = 44.0;
    const bottomLabelH = 24.0;
    const chartTotalH = 200.0;
    const chartAreaH = chartTotalH - bottomLabelH;
    const barGroupW = 56.0;
    const barW = 16.0;
    const barGap = 4.0;
    final totalContentW = yLabelW + chartData.length * barGroupW + 12.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      child: PremiumGlass(
        padding: const EdgeInsets.all(20),
        borderRadius: 18,
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  S.t(context, 'monthly_comparison'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.gray700,
                  ),
                ),
                const Spacer(),
                _chartLegend(AppColors.emerald, S.t(context, 'income')),
                const SizedBox(width: 12),
                _chartLegend(AppColors.expenseDark, S.t(context, 'expense')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: chartTotalH,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final minW = max(totalContentW, constraints.maxWidth);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: minW,
                      height: chartTotalH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ...List.generate(5, (i) {
                            final y = chartAreaH * (1 - i / 4);
                            return Positioned(
                              left: 0,
                              right: 0,
                              top: y,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: yLabelW - 4,
                                    child: Text(
                                      '${(yMax * i / 4).toInt()}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[400],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Container(
                                        height: i == 0 ? 1.5 : 0.5,
                                        color: Colors.grey.withAlpha(
                                          i == 0 ? 120 : 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Positioned(
                            left: yLabelW,
                            top: 0,
                            bottom: bottomLabelH,
                            child: Container(
                              width: 1,
                              color: Colors.grey.withAlpha(80),
                            ),
                          ),
                          ...chartData.asMap().entries.expand((entry) {
                            final idx = entry.key;
                            final d = entry.value;
                            final gl = yLabelW + idx * barGroupW;
                            final incomeH =
                                yMax > 0
                                    ? (d.income / yMax * chartAreaH).clamp(
                                        0.0,
                                        chartAreaH,
                                      )
                                    : 0.0;
                            final expenseH =
                                yMax > 0
                                    ? (d.expense / yMax * chartAreaH).clamp(
                                        0.0,
                                        chartAreaH,
                                      )
                                    : 0.0;
                            final children = <Widget>[];

                            if (d.income > 0) {
                              children.add(
                                Positioned(
                                  bottom: bottomLabelH,
                                  left:
                                      gl + barGroupW / 2 - barW - barGap / 2,
                                  width: barW,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey('inc_${idx}_${d.label}'),
                                    tween: Tween(begin: 0.0, end: incomeH),
                                    duration: Duration(
                                      milliseconds: 500 + idx * 60,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (ctx, h, _) => BounceTap(
                                      onTap: () =>
                                          onMonthTap(d.label, 'income', d.income),
                                      child: Container(
                                        height: h,
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (d.expense > 0) {
                              children.add(
                                Positioned(
                                  bottom: bottomLabelH,
                                  left:
                                      gl + barGroupW / 2 + barGap / 2,
                                  width: barW,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey('exp_${idx}_${d.label}'),
                                    tween: Tween(begin: 0.0, end: expenseH),
                                    duration: Duration(
                                      milliseconds: 500 + idx * 60,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (ctx, h, _) => BounceTap(
                                      onTap: () =>
                                          onMonthTap(d.label, 'expense', d.expense),
                                      child: Container(
                                        height: h,
                                        decoration: BoxDecoration(
                                          color: AppColors.expenseDark,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (d.income > 0) {
                              children.add(
                                Positioned(
                                  bottom: bottomLabelH + incomeH + 3,
                                  left:
                                      gl + barGroupW / 2 - barW - barGap / 2,
                                  width: barW,
                                  child: Text(
                                    '$currencySymbol${d.income.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (d.expense > 0) {
                              children.add(
                                Positioned(
                                  bottom: bottomLabelH + expenseH + 3,
                                  left:
                                      gl + barGroupW / 2 + barGap / 2,
                                  width: barW,
                                  child: Text(
                                    '$currencySymbol${d.expense.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.expenseDark,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              );
                            }
                            children.add(
                              Positioned(
                                bottom: 4,
                                left: gl,
                                width: barGroupW,
                                height: 20,
                                child: Text(
                                  d.label.substring(5),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                            return children;
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
