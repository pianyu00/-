import 'package:flutter/material.dart';
import '../../models/record.dart';
import '../../models/categories.dart';
import '../../utils/strings.dart';
import '../../widgets/premium_ui.dart';

Future<void> showMonthDetailSheet({
  required BuildContext context,
  required List<Record> records,
  required String type,
  required int year,
  required int month,
  required String currencySymbol,
  required String language,
  required String Function(int y, int m) ymFormatter,
  required void Function(String category, String type) onCategoryTap,
  required void Function(Record) onEditRecord,
  required Future<bool> Function(Record) onDeleteRecord,
}) {
  final catList = type == 'expense' ? expenseCategories : incomeCategories;
  final color = type == 'expense' ? Colors.red : Colors.green;

  final totals = <String, double>{};
  double total = 0;
  for (final r in records) {
    totals[r.category] = (totals[r.category] ?? 0) + r.amount;
    total += r.amount;
  }
  final sorted =
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
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
            Row(
              children: [
                Text(
                  ymFormatter(year, month),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  type == 'income'
                      ? S.t(context, 'income')
                      : S.t(context, 'expense'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${S.t(context, 'total')} $currencySymbol${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    S.t(context, 'no_records'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ),
              ),
            ...sorted.map((entry) {
              final cat =
                  catList.where((c) => c.name == entry.key).firstOrNull;
              final pct = total > 0 ? entry.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCategoryTap(entry.key, type);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cat?.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            cat?.icon ?? Icons.help_outline,
                            color: cat?.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryDisplayName(entry.key, language),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GlowProgressBar(
                                value: pct.clamp(0.0, 1.0),
                                color: cat?.color ??
                                    Theme.of(ctx).colorScheme.primary,
                                height: 4,
                                borderRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$currencySymbol${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (sorted.isNotEmpty) const SizedBox.shrink(),
          ],
        ),
      );
    },
  );
}
