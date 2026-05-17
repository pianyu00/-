import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../models/categories.dart';
import '../models/app_themes.dart';
import '../providers/app_settings_provider.dart';
import '../utils/strings.dart';
import '../widgets/premium_ui.dart';

class AddRecordPage extends StatefulWidget {
  final Record? record;

  const AddRecordPage({super.key, this.record});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  String _type = 'expense';
  String _category = '餐饮';
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    if (widget.record != null) {
      final r = widget.record!;
      _amountController.text = r.amount.toString();
      _type = r.type;
      _category = r.category;
      _selectedDate = DateTime.parse(r.date);
      _noteController.text = r.note;
    }

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<CategoryInfo> get _categories =>
      _type == 'expense' ? expenseCategories : incomeCategories;
  String get _lang => context.read<AppSettingsProvider>().language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final themeIndex = context.read<AppSettingsProvider>().themeIndex;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appThemes[themeIndex].darkSurfaceColor,
                  appThemes[themeIndex].darkBgColor,
                  appThemes[themeIndex].darkBgColor,
                ],
              )
            : appThemes[themeIndex].backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.record != null
                                ? S.t(context, 'edit_record_title')
                                : S.t(context, 'add_record_title'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF202124),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : AppColors.gray500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('M/d').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Type Toggle ──
                      PremiumGlass(
                        padding: const EdgeInsets.all(4),
                        borderRadius: AppRadius.md,
                        tintColor: isDark ? AppColors.darkCard : AppColors.gray100,
                        border: isDark
                            ? Border.all(color: AppColors.frostBorder)
                            : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTypeToggle(
                                'expense',
                                S.t(context, 'expense'),
                                Icons.trending_down_rounded,
                                const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildTypeToggle(
                                'income',
                                S.t(context, 'income'),
                                Icons.trending_up_rounded,
                                const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Amount Input ──
                      Text(
                        S.t(context, 'amount'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.frostBorder
                                : AppColors.gray200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              context.read<AppSettingsProvider>().currencySymbol,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.gray900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.gray900,
                                  letterSpacing: -0.5,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : AppColors.gray300,
                                  ),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return S.t(context, 'amount_required');
                                  }
                                  if (double.tryParse(v) == null ||
                                      double.parse(v) <= 0) {
                                    return S.t(context, 'amount_invalid');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Category Grid ──
                      Text(
                        S.t(context, 'category'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 14,
                        children: _categories.map((cat) {
                          final selected = _category == cat.name;
                          return GestureDetector(
                            onTap: () => setState(() => _category = cat.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cat.color.withValues(alpha: 0.12)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : AppColors.gray50),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: selected
                                    ? Border.all(
                                        color: cat.color.withValues(alpha: 0.4),
                                        width: 1.5,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                      ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon, color: cat.color, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    categoryDisplayName(cat.name, _lang),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? cat.color
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.5)
                                              : AppColors.gray500),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // ── Note Input ──
                      Text(
                        S.t(context, 'note_optional'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.frostBorder
                                : AppColors.gray200,
                          ),
                        ),
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: S.t(context, 'note_hint'),
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppColors.gray400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : AppColors.gray700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Premium Save Button ──
                      GestureDetector(
                        onTap: _saveRecord,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.emerald,
                                      AppColors.emeraldDark,
                                    ]
                                  : [
                                      primary,
                                      primary.withValues(alpha: 0.85),
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: AppColors.emerald.withValues(alpha: 0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: AppColors.emerald.withValues(alpha: 0.12),
                                      blurRadius: 48,
                                      spreadRadius: 4,
                                      offset: const Offset(0, -2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Text(
                              widget.record != null
                                  ? S.t(context, 'save_changes')
                                  : S.t(context, 'save'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type, String label, IconData icon, Color color) {
    final selected = _type == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          if (!_categories.any((c) => c.name == _category)) {
            _category = _categories.first.name;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? color.withValues(alpha: 0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: selected && !isDark
              ? AppShadows.soft
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.gray400),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? color
                    : (isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('zh'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final today = DateTime.now();
    final normSelected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final normToday = DateTime(today.year, today.month, today.day);
    if (normSelected.isAfter(normToday)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t(context, 'time_travel_hint')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final record = Record(
      id: widget.record?.id,
      amount: double.parse(_amountController.text),
      type: _type,
      category: _category,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      time: widget.record?.time ?? DateFormat('HH:mm:ss').format(now),
      note: _noteController.text,
    );

    Navigator.pop(context, record);
  }
}
