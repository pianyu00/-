import 'package:flutter/material.dart';
import '../../models/record.dart';
import '../../models/categories.dart';
import '../../models/app_themes.dart';
import '../../widgets/animated_counter.dart';

class RecordRow extends StatelessWidget {
  final Record record;
  final String currencySymbol;
  final String language;
  final VoidCallback onTap;

  const RecordRow({
    super.key,
    required this.record,
    required this.currencySymbol,
    required this.language,
    required this.onTap,
  });

  CategoryInfo? _catInfo() {
    final list = record.type == 'expense' ? expenseCategories : incomeCategories;
    for (final c in list) {
      if (c.name == record.category) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cat = _catInfo();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cat?.color.withValues(alpha: isDark ? 0.15 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cat?.icon ?? Icons.help_outline,
                color: cat?.color,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryDisplayName(record.category, language),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (record.note.isNotEmpty)
                    Text(
                      record.note,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${record.type == "expense" ? "-" : "+"}$currencySymbol',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: record.type == 'expense'
                        ? (isDark
                            ? AppColors.expenseDark
                            : AppColors.expenseLight)
                        : (isDark
                            ? AppColors.incomeDark
                            : AppColors.incomeLight),
                  ),
                ),
                AnimatedCounter(
                  value: record.amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: record.type == 'expense'
                        ? (isDark
                            ? AppColors.expenseDark
                            : AppColors.expenseLight)
                        : (isDark
                            ? AppColors.incomeDark
                            : AppColors.incomeLight),
                  ),
                  duration: const Duration(milliseconds: 800),
                  decimals: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
