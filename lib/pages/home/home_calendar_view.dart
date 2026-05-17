import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/record.dart';
import '../../models/app_themes.dart';
import '../../utils/strings.dart';
import '../../widgets/premium_ui.dart';

class HomeCalendarView extends StatelessWidget {
  final int year;
  final int month;
  final List<Record> records;
  final void Function(int day) onDayTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const HomeCalendarView({
    super.key,
    required this.year,
    required this.month,
    required this.records,
    required this.onDayTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final dayMap = <int, double>{};
    final dayIncomeMap = <int, double>{};
    for (final r in records) {
      final d = DateTime.parse(r.date).day;
      if (r.type == 'expense') {
        dayMap[d] = (dayMap[d] ?? 0) + r.amount;
      } else {
        dayIncomeMap[d] = (dayIncomeMap[d] ?? 0) + r.amount;
      }
    }

    final now = DateTime.now();
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final dayNames = [
      S.t(context, 'mon'),
      S.t(context, 'tue'),
      S.t(context, 'wed'),
      S.t(context, 'thu'),
      S.t(context, 'fri'),
      S.t(context, 'sat'),
      S.t(context, 'sun'),
    ];
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -50) {
            onNextMonth();
          } else if (details.primaryVelocity! > 50) {
            onPreviousMonth();
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Padding(
          key: ValueKey('$year-$month'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: PremiumGlass(
            padding: const EdgeInsets.all(12),
            borderRadius: 18,
            child: Column(
              children: [
                Row(
                  children:
                      dayNames
                          .map(
                            (n) => Expanded(
                              child: Center(
                                child: Text(
                                  n,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                ...List.generate((startWeekday - 1 + daysInMonth + 6) ~/ 7, (
                  row,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: List.generate(7, (col) {
                        final day = row * 7 + col - startWeekday + 2;
                        if (day < 1 || day > daysInMonth) {
                          return const Expanded(child: SizedBox(height: 60));
                        }

                        final expense = dayMap[day];
                        final income = dayIncomeMap[day];
                        final isToday =
                            year == now.year &&
                            month == now.month &&
                            day == now.day;
                        final hasRecord = expense != null || income != null;

                        return Expanded(
                          child: GestureDetector(
                            onTap: hasRecord ? () {
                              HapticFeedback.lightImpact();
                              onDayTap(day);
                            } : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 60,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? primary.withValues(alpha: 0.1)
                                    : hasRecord
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : primary.withValues(alpha: 0.03))
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: isToday
                                    ? Border.all(
                                        color: primary.withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          isToday
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isToday
                                              ? primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                    ),
                                  ),
                                  if (expense != null)
                                    Text(
                                      '-${expense.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.red[200],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (income != null)
                                    Text(
                                      '+${income.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.green,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
}
