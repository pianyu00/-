import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/record.dart';
import '../models/categories.dart';
import '../models/app_themes.dart';
import '../providers/app_settings_provider.dart';
import '../pages/home/home_chart_view.dart';
import '../utils/encouragements.dart';
import '../utils/strings.dart';
import '../widgets/animated_counter.dart';
import '../widgets/premium_ui.dart';
import 'add_record_page.dart';
import 'home/home_list_view.dart';
import 'home/home_calendar_view.dart';
import 'home/home_day_detail_sheet.dart';
import 'home/home_month_detail_sheet.dart';
import 'home/home_pie_chart_view.dart';
import 'home/home_record_row.dart';
import 'search_page.dart';
import 'settings_page.dart';

// ── Chart data model ──
// ── Home Page ──
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _db = DatabaseHelper();
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  List<Record> _records = [];
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  // Feedback animation
  double? _feedbackAmount;
  bool? _feedbackIsExpense;
  String? _encouragement;
  late AnimationController _fbController;
  late Animation<double> _fbOpacity;
  late Animation<double> _fbOffset;
  late Animation<double> _fbScale;
  bool _showFeedback = false;

  int _viewMode = 0; // 0=list, 1=calendar, 2=chart
  int _catTabIndex = 0; // 0=expense, 1=income
  bool _pullTriggered = false;
  double _initialTouchY = 0;
  double _initialTouchX = 0;
  double? _chartDragStartX;
  String _bookName = '轻记账';
  String get _cs => context.read<AppSettingsProvider>().currencySymbol;
  String get _lang => context.read<AppSettingsProvider>().language;
  String _ym(int y, int m) => S
      .t(context, 'year_month')
      .replaceAll('%y', y.toString())
      .replaceAll('%m', m.toString());
  final _scrollController = ScrollController();
  List<MonthlySummary> _chartData = [];

  // Premium animation controllers
  late AnimationController _staggerController;
  late AnimationController _breathController;
  late Animation<double> _balanceScaleAnim;
  late AnimationController _fabFloatController;
  late Animation<double> _fabFloatAnim;

  @override
  void initState() {
    super.initState();
    _fbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // Scale: spring bounce in from 30% to 100% (overshoots then settles)
    _fbScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _fbController,
        curve: const Interval(0, 0.45, curve: Curves.elasticOut),
      ),
    );
    // Offset: slight delay then float up smoothly
    _fbOffset = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fbController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    // Opacity: stay visible most of the time, fade near the end
    _fbOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fbController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _fbController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showFeedback = false);
      }
    });

    _loadRecords();
    _loadBookName();
    _autoCompact();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _balanceScaleAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const ElasticOutCurve(0.6),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Start entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _staggerController.forward();
    });

    _fabFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fabFloatAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabFloatController, curve: Curves.easeInOutSine),
    );
  }

  Future<void> _autoCompact() async {
    await _db.compactDatabase();
  }

  Future<void> _loadBookName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('book_name');
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _bookName = name);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fbController.dispose();
    _staggerController.dispose();
    _breathController.dispose();
    _fabFloatController.dispose();
    super.dispose();
  }

  void _loadRecords({int? year, int? month}) async {
    final y = year ?? _year;
    final m = month ?? _month;
    final records = await _db.getRecordsByMonth(y, m);
    final summary = await _db.getMonthlySummary(y, m);
    final chartRaw = await _db.getMonthlySummaries(y, m, 24);
    final monthIncome = <String, double>{};
    final monthExpense = <String, double>{};
    final monthSet = <String>{};
    for (final row in chartRaw) {
      final mStr = row['month'] as String;
      final type = row['type'] as String;
      final total = (row['total'] as num).toDouble();
      monthSet.add(mStr);
      if (type == 'income') {
        monthIncome[mStr] = (monthIncome[mStr] ?? 0) + total;
      } else {
        monthExpense[mStr] = (monthExpense[mStr] ?? 0) + total;
      }
    }
    final sorted = monthSet.toList()..sort();
    final chartData =
        sorted
            .map(
              (mStr) => MonthlySummary(
                mStr,
                monthIncome[mStr] ?? 0,
                monthExpense[mStr] ?? 0,
              ),
            )
            .toList();

    setState(() {
      _year = y;
      _month = m;
      _records = records;
      _monthlyIncome = summary['income'] ?? 0;
      _monthlyExpense = summary['expense'] ?? 0;
      _chartData = chartData;
    });
  }

  void _previousMonth() {
    int y = _year, m = _month - 1;
    if (m == 0) {
      m = 12;
      y--;
    }
    _loadRecords(year: y, month: m);
  }

  void _nextMonth() {
    int y = _year, m = _month + 1;
    if (m == 13) {
      m = 1;
      y++;
    }
    _loadRecords(year: y, month: m);
  }

  Future<void> _addRecord() async {
    HapticFeedback.lightImpact();
    final record = await Navigator.push<Record>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (ctx, a1, a2) => const AddRecordPage(),
        transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );

    if (record != null) {
      await _db.insertRecord(record);
      _loadRecords();
      setState(() {
        _feedbackAmount = record.amount;
        _feedbackIsExpense = record.type == 'expense';
        _encouragement = getWeightedEncouragement(record.type, lang: _lang);
        _showFeedback = true;
      });
      _fbController.reset();
      _fbController.forward();
    }
  }

  Future<void> _editRecord(Record record) async {
    final result = await Navigator.push<Record>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (ctx, a1, a2) => AddRecordPage(record: record),
        transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );
    if (result != null) {
      await _db.updateRecord(result);
      _loadRecords();
    }
  }

  Future<void> _openSearch() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, a1, a2) => const SearchPage(),
        transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );
    _pullTriggered = false;
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _bookName);
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(S.t(ctx, 'rename_book')),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: S.t(ctx, 'book_name_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(S.t(ctx, 'cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: Text(S.t(ctx, 'ok')),
              ),
            ],
          ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result != _bookName) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_name', result);
      if (mounted) setState(() => _bookName = result);
    }
  }

  void _showTypeBreakdown(String label, String type) {
    final totals = <String, double>{};
    double total = 0;
    for (final r in _records) {
      if (r.type != type) continue;
      totals[r.category] = (totals[r.category] ?? 0) + r.amount;
      total += r.amount;
    }

    final catList = type == 'expense' ? expenseCategories : incomeCategories;
    final sorted =
        totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final color = type == 'expense' ? Colors.red : Colors.green;

    showModalBottomSheet(
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
                    '${_ym(_year, _month)} ',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${S.t(context, 'total')} $_cs${total.toStringAsFixed(2)}',
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
                      _showCategoryDetail(entry.key, type);
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
                                  categoryDisplayName(entry.key, _lang),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GlowProgressBar(
                                  value: pct.clamp(0.0, 1.0),
                                  color: cat?.color ?? Theme.of(ctx).colorScheme.primary,
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
                            '$_cs${entry.value.toStringAsFixed(2)}',
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
            ],
          ),
        );
      },
    );
  }

  Future<bool> _onDeleteRecord(Record r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t(ctx, 'confirm_delete')),
        content: Text(S.t(ctx, 'confirm_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t(ctx, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t(ctx, 'delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteRecord(r.id!);
      _loadRecords();
      return true;
    }
    return false;
  }

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
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: GestureDetector(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _bookName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.gray400,
              ),
            ],
          ),
        ),
        actions: [
          _buildGlassActionButton(Icons.search_rounded, _openSearch),
          _buildGlassActionButton(Icons.tune_rounded, () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, a1, a2) => const SettingsPage(),
                transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
              ),
            ).then((cleared) {
              if (cleared == true) _loadRecords();
            });
          }, rightPadding: 12),
        ],
      ),
      body: Stack(
        children: [
          // ── Ambient background glow ──
          if (isDark) _buildAmbientBackground(primary),

          Listener(
            onPointerDown: (event) {
              _initialTouchY = event.position.dy;
              _initialTouchX = event.position.dx;
            },
            onPointerMove: (event) {
              if (!_pullTriggered &&
                  event.position.dy > _initialTouchY + 100) {
                final dx = (event.position.dx - _initialTouchX).abs();
                if (dx > 60) return;
                if (_scrollController.hasClients &&
                    _scrollController.position.pixels <=
                        _scrollController.position.minScrollExtent + 1) {
                  _pullTriggered = true;
                  _openSearch();
                }
              }
            },
            child: BreathingWidget(
              duration: const Duration(seconds: 4),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    RepaintBoundary(child: _buildBalanceGlowCard()),
                    _buildGlassStats(),
                    const SizedBox(height: 8),
                    _buildPremiumMonthNav(),
                    RepaintBoundary(child: _buildCategoryBreakdown(primary)),
                    const SizedBox(height: 4),
                    ClipRect(
                      child: RepaintBoundary(
                        child: Stack(
                          children: [
                            _fadeView(
                              () => HomeListView(
                                records: _records,
                                currencySymbol: _cs,
                                language: _lang,
                                onEditRecord: _editRecord,
                                onDeleteRecord: _onDeleteRecord,
                              ),
                              0,
                            ),
                            _fadeView(
                              () => HomeCalendarView(
                                year: _year,
                                month: _month,
                                records: _records,
                                onDayTap: (day) => showDayDetailSheet(
                                  context: context,
                                  records: _records.where((r) => DateTime.parse(r.date).day == day).toList(),
                                  month: _month,
                                  day: day,
                                  currencySymbol: _cs,
                                  language: _lang,
                                  onEditRecord: _editRecord,
                                  onDeleteRecord: _onDeleteRecord,
                                ),
                                onPreviousMonth: _previousMonth,
                                onNextMonth: _nextMonth,
                              ),
                              1,
                            ),
                            _fadeView(_buildChartView, 2),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // ── Feedback animation overlay ──
          if (_showFeedback && _feedbackAmount != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: IgnorePointer(child: _buildFeedback()),
            ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
      floatingActionButton: _buildPremiumFAB(),
      ),
    );
  }

  // ── Premium UI Methods ──

  Widget _buildGlassActionButton(IconData icon, VoidCallback onPressed, {double rightPadding = 4}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(right: rightPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1AFFFFFF) : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isDark
            ? Border.all(color: AppColors.frostBorder)
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.gray500,
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildAmbientBackground(Color accentColor) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Top-right ambient glow
            Positioned(
              top: -100,
              right: -80,
              width: 300,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.08),
                      accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Center-left ambient glow
            Positioned(
              top: 200,
              left: -120,
              width: 350,
              height: 350,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.05),
                      accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _fabFloatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -6 * _fabFloatAnim.value),
        child: child,
      ),
      child: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildGlassBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.glassWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.frostBorder : AppColors.gray200.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGlassNavItem(Icons.list_rounded, S.t(context, 'list_view'), 0),
              _buildGlassNavItem(Icons.calendar_month_rounded, S.t(context, 'calendar_view'), 1),
              _buildGlassNavItem(Icons.bar_chart_rounded, S.t(context, 'chart_view'), 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem(IconData icon, String label, int index) {
    final selected = _viewMode == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _viewMode = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.12 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? accent : (isDark ? AppColors.gray400 : AppColors.gray400),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? accent : (isDark ? AppColors.gray400 : AppColors.gray500),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMonthNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -50) {
              _nextMonth();
            } else if (details.primaryVelocity! > 50) {
              _previousMonth();
            }
          }
        },
        child: PremiumGlass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 14,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _previousMonth();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.gray500,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 14,
                  color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  _ym(_year, _month),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _nextMonth();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBalanceGlowCard() {
    final balance = _monthlyIncome - _monthlyExpense;
    final isPositive = balance >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _balanceScaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _balanceScaleAnim.value,
        child: child,
      ),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AmbientGlow(
        color: isPositive ? AppColors.emerald : AppColors.expenseDark,
        radius: 180,
        opacity: 0.12,
        child: PremiumGlass(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          boxShadow: isDark ? AppShadows.cardDarkElevated : AppShadows.medium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.t(context, 'balance'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.gray500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _cs,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedCounter(
                      value: balance.abs(),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? (isDark ? Colors.white : AppColors.textPrimary)
                            : AppColors.expense,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                      duration: const Duration(milliseconds: 1200),
                      decimals: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildGlassStats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showTypeBreakdown(S.t(context, 'income'), 'income'),
              child: PremiumGlass(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                borderRadius: 14,
                boxShadow: isDark ? AppShadows.cardDark : AppShadows.soft,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up_rounded, color: AppColors.emerald, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t(context, 'income'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedCounter(
                          value: _monthlyIncome,
                          prefix: _cs,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.emerald : AppColors.premiumGreen,
                          ),
                          duration: const Duration(milliseconds: 1000),
                          decimals: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _showTypeBreakdown(S.t(context, 'expense'), 'expense'),
              child: PremiumGlass(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                borderRadius: 14,
                boxShadow: isDark ? AppShadows.cardDark : AppShadows.soft,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.expenseDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_down_rounded, color: AppColors.expenseDark, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t(context, 'expense'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedCounter(
                          value: _monthlyExpense,
                          prefix: _cs,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.expenseDark : AppColors.expenseAmtLight,
                          ),
                          duration: const Duration(milliseconds: 1000),
                          decimals: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category breakdown (swipeable expense/income) ──
  Widget _buildCategoryBreakdown(Color primary) {
    if (_records.isEmpty) return const SizedBox.shrink();

    // Aggregate expense by category
    final expenseTotals = <String, double>{};
    double expenseTotal = 0;
    for (final r in _records) {
      if (r.type != 'expense') continue;
      expenseTotals[r.category] = (expenseTotals[r.category] ?? 0) + r.amount;
      expenseTotal += r.amount;
    }

    // Aggregate income by category
    final incomeTotals = <String, double>{};
    double incomeTotal = 0;
    for (final r in _records) {
      if (r.type != 'income') continue;
      incomeTotals[r.category] = (incomeTotals[r.category] ?? 0) + r.amount;
      incomeTotal += r.amount;
    }

    if (expenseTotals.isEmpty && incomeTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: PremiumGlass(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, size: 16, color: primary),
                const SizedBox(width: 6),
                Text(
                  S.t(context, 'category'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.gray700,
                  ),
                ),
                const Spacer(),
                _buildTabChip(S.t(context, 'expense'), 0, AppColors.expenseLight),
                const SizedBox(width: 6),
                _buildTabChip(S.t(context, 'income'), 1, AppColors.incomeLight),
              ],
            ),
            const SizedBox(height: 12),
              // Swipeable content
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -50 && _catTabIndex == 0) {
                      setState(() => _catTabIndex = 1);
                    } else if (details.primaryVelocity! > 50 &&
                        _catTabIndex == 1) {
                      setState(() => _catTabIndex = 0);
                    }
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                  child:
                      _catTabIndex == 0
                          ? _buildCategoryList(
                            expenseTotals,
                            expenseTotal,
                            expenseCategories,
                            S.t(context, 'no_expense_records'),
                            key: const ValueKey('expense_cats'),
                          )
                          : _buildCategoryList(
                            incomeTotals,
                            incomeTotal,
                            incomeCategories,
                            S.t(context, 'no_income_records'),
                            key: const ValueKey('income_cats'),
                          ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildTabChip(String label, int index, Color color) {
    final selected = _catTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _catTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.gray100),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? color
                : (isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.gray500),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    Map<String, double> catTotals,
    double total,
    List<CategoryInfo> catList,
    String emptyText, {
    required Key key,
  }) {
    final sorted =
        catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return SizedBox(
        key: key,
        height: 60,
        child: Center(
          child: Text(
            emptyText,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ),
      );
    }

    final type = catList == expenseCategories ? 'expense' : 'income';

    return SizedBox(
      key: key,
      child: Column(
        children: [
          ...sorted.take(6).map((entry) {
            final cat = catList.where((c) => c.name == entry.key).firstOrNull;
            final pct = total > 0 ? entry.value / total : 0.0;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCategoryDetail(entry.key, type),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cat?.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        cat?.icon ?? Icons.help_outline,
                        color: cat?.color,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        categoryDisplayName(entry.key, _lang),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GlowProgressBar(
                        value: pct.clamp(0.0, 1.0),
                        color: cat?.color ?? Theme.of(context).colorScheme.primary,
                        height: 6,
                        borderRadius: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_cs${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (sorted.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                S
                    .t(context, 'more_categories')
                    .replaceAll('%d', (sorted.length - 6).toString()),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  void _showCategoryDetail(String category, String type) {
    final dayRecords =
        _records
            .where((r) => r.type == type && r.category == category)
            .toList();
    final total = dayRecords.fold(0.0, (s, r) => s + r.amount);
    final catList = type == 'expense' ? expenseCategories : incomeCategories;
    final cat = catList.where((c) => c.name == category).firstOrNull;
    final accentColor = type == 'expense' ? Colors.red : Colors.green;

    showModalBottomSheet(
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cat?.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cat?.icon ?? Icons.help_outline,
                      color: cat?.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    categoryDisplayName(category, _lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${S.t(context, 'total')} $_cs${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
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
                confirmDismiss: (_) => _onDeleteRecord(r),
                child: RecordRow(
                  record: r,
                  currencySymbol: _cs,
                  language: _lang,
                  onTap: () => _editRecord(r),
                ),
              )),
              if (dayRecords.isEmpty)
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

  Widget _fadeView(Widget Function() builder, int mode) {
    return AnimatedOpacity(
      opacity: _viewMode == mode ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedSlide(
        offset: _viewMode == mode ? Offset.zero : const Offset(0, 0.03),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(ignoring: _viewMode != mode, child: builder()),
      ),
    );
  }

  Widget _buildChartView() {
    return Listener(
      onPointerDown: (event) {
        _chartDragStartX = event.position.dx;
      },
      onPointerMove: (event) {
        if (_chartDragStartX != null) {
          final dx = event.position.dx - _chartDragStartX!;
          if (dx.abs() > 60) {
            _chartDragStartX = null;
            HapticFeedback.lightImpact();
            if (dx < 0) {
              _nextMonth();
            } else {
              _previousMonth();
            }
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Column(
          key: ValueKey('$_year-$_month'),
          children: [
            HomeChartView(
              chartData: _chartData,
              currencySymbol: _cs,
              dateFormat: _lang == 'en' ? 'MM/dd/yyyy' : 'yyyy-MM-dd',
              onMonthTap: (label, type, amount) => _showMonthDetail(label, type, amount),
            ),
            HomePieChartView(
              records: _records,
              currencySymbol: _cs,
              language: _lang,
              year: _year,
              month: _month,
              onCategoryTap: _showCategoryDetail,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthDetail(
    String label,
    String type,
    double amount,
  ) async {
    final parts = label.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final records = await _db.getRecordsByMonth(year, month);
    final filtered = records.where((r) => r.type == type).toList();
    if (!mounted) return;
    showMonthDetailSheet(
      context: context,
      records: filtered,
      type: type,
      year: year,
      month: month,
      currencySymbol: _cs,
      language: _lang,
      ymFormatter: _ym,
      onCategoryTap: _showCategoryDetail,
      onEditRecord: _editRecord,
      onDeleteRecord: _onDeleteRecord,
    );
  }


  // ── Search helpers ──
  // Feedback animation overlay
  Widget _buildFeedback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _feedbackIsExpense == true ? Colors.red : Colors.green;
    final prefix = _feedbackIsExpense == true ? '-$_cs' : '+$_cs';
    final text = '$prefix${_feedbackAmount!.toStringAsFixed(2)}';
    final driftX = Random().nextDouble() * 60 - 30;

    return AnimatedBuilder(
      animation: _fbController,
      builder: (ctx, _) {
        return Opacity(
          opacity: _fbOpacity.value,
          child: Transform.translate(
            offset: Offset(driftX * _fbOffset.value, -_fbOffset.value * 180),
            child: Transform.scale(
              scale: _fbScale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        Icons.star_rounded,
                        size: 6.0 + i * 4,
                        color: color.withValues(alpha: 0.5 - i * 0.08),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Premium feedback card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardElevated : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? color.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.25),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.08 : 0),
                          blurRadius: 64,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _feedbackIsExpense == true
                              ? S.t(context, 'recorded')
                              : S.t(context, 'saved_success'),
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                        if (_encouragement != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _encouragement!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
