import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/record.dart';
import '../../models/categories.dart';
import '../../models/app_themes.dart';
import '../../utils/strings.dart';
import '../../widgets/premium_ui.dart';

class HomePieChartView extends StatefulWidget {
  final List<Record> records;
  final String currencySymbol;
  final String language;
  final int year;
  final int month;
  final void Function(String category, String type) onCategoryTap;

  const HomePieChartView({
    super.key,
    required this.records,
    required this.currencySymbol,
    required this.language,
    required this.year,
    required this.month,
    required this.onCategoryTap,
  });

  @override
  State<HomePieChartView> createState() => _HomePieChartViewState();
}

class _HomePieChartViewState extends State<HomePieChartView>
    with SingleTickerProviderStateMixin {
  int _typeIndex = 0;
  int? _touchedIndex;
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  String get _type => _typeIndex == 0 ? 'expense' : 'income';

  List<MapEntry<String, double>> _getSortedTotals() {
    final totals = <String, double>{};
    for (final r in widget.records) {
      if (r.type != _type) continue;
      totals[r.category] = (totals[r.category] ?? 0) + r.amount;
    }
    final entries = totals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getSortedTotals();
    final totalAmount = totals.fold(0.0, (s, e) => s + e.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accentColor =
        _type == 'expense' ? AppColors.expenseAmtLight : AppColors.incomeLight;

    if (totalAmount <= 0) {
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
                  Icon(Icons.pie_chart_rounded, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t(context, 'category_breakdown'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.year}-${widget.month.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48, color: isDark ? Colors.white12 : Colors.grey[200]),
                    const SizedBox(height: 12),
                    Text(
                      S.t(context, 'no_chart_data'),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white38 : AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.t(context, 'add_more_chart_hint'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white24 : AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    final catList = _type == 'expense' ? expenseCategories : incomeCategories;
    final sections = _buildSections(totals, catList, totalAmount);

    return FadeTransition(
      opacity: _entranceAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          child: PremiumGlass(
            padding: const EdgeInsets.all(20),
            borderRadius: 18,
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.pie_chart_rounded, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t(context, 'category_breakdown'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.year}-${widget.month.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildToggleChip(
                      S.t(context, 'expense'), 0, AppColors.expenseLight),
                    const SizedBox(width: 6),
                    _buildToggleChip(
                      S.t(context, 'income'), 1, AppColors.incomeLight),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Donut chart ──
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 48,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _touchedIndex = null;
                                  return;
                                }
                                final idx = response
                                    .touchedSection!.touchedSectionIndex;
                                _touchedIndex = idx;
                                if (event is FlTapUpEvent) {
                                  final entry = totals[idx];
                                  widget.onCategoryTap(entry.key, _type);
                                }
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      ),
                      // ── Donut center text ──
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.currencySymbol}${totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _type == 'expense'
                                ? S.t(context, 'expense')
                                : S.t(context, 'income'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Legend ──
                ...List.generate(totals.length, (i) {
                  final entry = totals[i];
                  final cat =
                      catList.where((c) => c.name == entry.key).firstOrNull;
                  final pct = entry.value / totalAmount;
                  final isTouched = _touchedIndex == i;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => widget.onCategoryTap(entry.key, _type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isTouched
                              ? (cat?.color ?? Colors.grey)
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isTouched ? 12 : 10,
                              height: isTouched ? 12 : 10,
                              decoration: BoxDecoration(
                                color: cat?.color ?? Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                categoryDisplayName(entry.key, widget.language),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isTouched ? FontWeight.w600 : FontWeight.w400,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.gray700,
                                ),
                              ),
                            ),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.gray500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${widget.currencySymbol}${entry.value.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> totals,
    List<CategoryInfo> catList,
    double totalAmount,
  ) {
    return List.generate(totals.length, (i) {
      final entry = totals[i];
      final cat = catList.where((c) => c.name == entry.key).firstOrNull;
      final pct = entry.value / totalAmount;
      final isTouched = _touchedIndex == i;

      return PieChartSectionData(
        color: cat?.color ?? Colors.grey,
        value: entry.value,
        title: pct >= 0.05 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
        radius: isTouched ? 58 : 46,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(blurRadius: 4, color: Colors.black38),
          ],
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: cat?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (cat?.color ?? Colors.grey).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  cat?.icon ?? Icons.touch_app,
                  size: 12,
                  color: Colors.white,
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.35,
      );
    });
  }

  Widget _buildToggleChip(String label, int index, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _typeIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _typeIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? color
                : (isDark ? Colors.white54 : AppColors.gray500),
          ),
        ),
      ),
    );
  }
}
