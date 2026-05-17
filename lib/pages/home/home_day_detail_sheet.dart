import 'package:flutter/material.dart';
import '../../models/record.dart';
import '../../utils/strings.dart';
import 'home_record_row.dart';

Future<void> showDayDetailSheet({
  required BuildContext context,
  required List<Record> records,
  required int month,
  required int day,
  required String currencySymbol,
  required String language,
  required void Function(Record) onEditRecord,
  required Future<bool> Function(Record) onDeleteRecord,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dayIncome =
          records
              .where((r) => r.type == 'income')
              .fold(0.0, (s, r) => s + r.amount);
      final dayExpense =
          records
              .where((r) => r.type == 'expense')
              .fold(0.0, (s, r) => s + r.amount);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.t(context, 'calendar_date')
                  .replaceAll('%m', month.toString())
                  .replaceAll('%d', day.toString()),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${S.t(context, 'income')} $currencySymbol${dayIncome.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.green[300] : Colors.green[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${S.t(context, 'expense')} $currencySymbol${dayExpense.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.red[300] : Colors.red[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${S.t(context, 'balance')} $currencySymbol${(dayIncome - dayExpense).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (dayIncome - dayExpense) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...records.map((r) => Dismissible(
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
              confirmDismiss: (_) => onDeleteRecord(r),
              child: RecordRow(
                record: r,
                currencySymbol: currencySymbol,
                language: language,
                onTap: () => onEditRecord(r),
              ),
            )),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    S.t(context, 'no_records'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
