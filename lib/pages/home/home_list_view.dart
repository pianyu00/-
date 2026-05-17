import 'package:flutter/material.dart';
import '../../models/record.dart';
import '../../models/app_themes.dart';
import '../../utils/strings.dart';
import '../../widgets/premium_ui.dart';
import 'home_record_row.dart';

class HomeListView extends StatelessWidget {
  final List<Record> records;
  final String currencySymbol;
  final String language;
  final void Function(Record) onEditRecord;
  final Future<bool> Function(Record) onDeleteRecord;

  const HomeListView({
    super.key,
    required this.records,
    required this.currencySymbol,
    required this.language,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  Map<String, List<Record>> _groupByDay(List<Record> records) {
    final map = <String, List<Record>>{};
    for (final r in records) {
      map.putIfAbsent(r.date, () => []).add(r);
    }
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return {for (final e in sorted) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                S.t(context, 'no_records_this_month'),
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              const SizedBox(height: 4),
              Text(
                S.t(context, 'tap_add_hint'),
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daily = _groupByDay(records);
    final dayNames = [
      S.t(context, 'mon'),
      S.t(context, 'tue'),
      S.t(context, 'wed'),
      S.t(context, 'thu'),
      S.t(context, 'fri'),
      S.t(context, 'sat'),
      S.t(context, 'sun'),
    ];
    final entries = daily.entries.toList();

    return Column(
      children: List.generate(entries.length, (i) {
        final dateStr = entries[i].key;
        final dayRecords = entries[i].value;
        final date = DateTime.parse(dateStr);
        final dayIncome = dayRecords
            .where((r) => r.type == 'income')
            .fold(0.0, (s, r) => s + r.amount);
        final dayExpense = dayRecords
            .where((r) => r.type == 'expense')
            .fold(0.0, (s, r) => s + r.amount);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOutCubic,
          key: ValueKey('${date.year}_${date.month}_$dateStr'),
          builder:
              (ctx, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - val)),
                  child: child,
                ),
              ),
          child: PremiumGlass(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          dayNames[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        children: [
                          if (dayExpense > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                '-$currencySymbol${dayExpense.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.expenseLight,
                                ),
                              ),
                            ),
                          if (dayIncome > 0)
                            Text(
                              '+$currencySymbol${dayIncome.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.incomeLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (dayExpense > 0 || dayIncome > 0)
                      Text(
                        '$currencySymbol${(dayIncome - dayExpense).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: (dayIncome - dayExpense) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...dayRecords.map((r) => Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return onDeleteRecord(r);
                  },
                  child: RecordRow(
                    record: r,
                    currencySymbol: currencySymbol,
                    language: language,
                    onTap: () => onEditRecord(r),
                  ),
                )),
              ],
            ),
          ),
        );
      }),
    );
  }
}
