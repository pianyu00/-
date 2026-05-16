import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../main.dart';
import '../models/record.dart';
import '../models/categories.dart';
import '../utils/encouragements.dart';
import '../utils/strings.dart';
import '../widgets/bounce_tap.dart';
import 'add_record_page.dart';
import 'search_page.dart';
import 'settings_page.dart';

// ── Chart data model ──
class _MonthlySummary {
  final String label;
  final double income;
  final double expense;
  _MonthlySummary(this.label, this.income, this.expense);
}

// ── Home Page ──
class HomePage extends StatefulWidget {
  final void Function(int) onThemeChanged;
  final int currentThemeIndex;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeIndex,
  });

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
  late AnimationController _gearController;
  late Animation<double> _gearScale;
  late Animation<double> _gearRotation;
  String _bookName = '轻记账';
  String get _cs => AccountBookApp.of(context)?.currencySymbol ?? '¥';
  String get _lang => AccountBookApp.of(context)?.language ?? 'zh';
  String _d(String dateStr) {
    final fmt = AccountBookApp.of(context)?.dateFormat ?? 'yyyy-MM-dd';
    if (fmt == 'yyyy-MM-dd') return dateStr;
    try {
      return DateFormat(fmt).format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _ym(int y, int m) => S
      .t(context, 'year_month')
      .replaceAll('%y', y.toString())
      .replaceAll('%m', m.toString());
  final _scrollController = ScrollController();
  List<_MonthlySummary> _chartData = [];

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

    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gearScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _gearController, curve: Curves.elasticOut),
    );
    _gearRotation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _gearController, curve: Curves.elasticOut),
    );

    _loadRecords();
    _loadBookName();
    _autoCompact();
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
    _gearController.dispose();
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
              (mStr) => _MonthlySummary(
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
    final record = await Navigator.push<Record>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecordPage()),
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
      MaterialPageRoute(builder: (_) => AddRecordPage(record: record)),
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
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, a1, a2) => const SearchPage(),
        transitionsBuilder:
            (ctx, a1, a2, child) => FadeTransition(opacity: a1, child: child),
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
                    '${S.t(context, 'total')} $_cs${total.toStringAsFixed(0)}',
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
                                LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(ctx).colorScheme.primary,
                                  ),
                                  minHeight: 4,
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
                            '$_cs${entry.value.toStringAsFixed(0)}',
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

  Map<String, List<Record>> _groupByDay(List<Record> records) {
    final map = <String, List<Record>>{};
    for (final r in records) {
      map.putIfAbsent(r.date, () => []).add(r);
    }
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return {for (final e in sorted) e.key: e.value};
  }

  CategoryInfo? _catInfo(Record r) {
    final list = r.type == 'expense' ? expenseCategories : incomeCategories;
    for (final c in list) {
      if (c.name == r.category) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTapUp: (_) async {
                _gearController.forward(from: 0.0);
                await Future.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((cleared) {
                  _gearController.reverse();
                  if (cleared == true) _loadRecords();
                });
              },
              child: AnimatedBuilder(
                animation: _gearController,
                builder: (ctx, child) {
                  final scale = _gearScale.value;
                  final angle = _gearRotation.value * 2 * pi;
                  return Transform(
                    transform:
                        Matrix4.identity()
                          ..rotateZ(angle)
                          ..scale(scale),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            title: InkWell(
              onTap: _showRenameDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_bookName, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              BounceTap(
                onTap: _openSearch,
                child: Tooltip(
                  message: S.t(context, 'search'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ),
              BounceTap(
                child: Tooltip(
                  message:
                      _viewMode == 0
                          ? S.t(context, 'calendar_view')
                          : _viewMode == 1
                          ? S.t(context, 'chart_view')
                          : S.t(context, 'list_view'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _viewMode == 0
                          ? Icons.calendar_month_outlined
                          : _viewMode == 1
                          ? Icons.bar_chart_outlined
                          : Icons.list_alt,
                      color: Colors.white,
                    ),
                  ),
                ),
                onTap: () => setState(() => _viewMode = (_viewMode + 1) % 3),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── Main scrollable content ──
              Listener(
                onPointerDown: (event) {
                  _initialTouchY = event.position.dy;
                },
                onPointerMove: (event) {
                  if (!_pullTriggered &&
                      event.position.dy > _initialTouchY + 25) {
                    if (_scrollController.hasClients &&
                        _scrollController.position.pixels <=
                            _scrollController.position.minScrollExtent + 1) {
                      _pullTriggered = true;
                      _openSearch();
                    }
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildMonthNav(),
                      _buildSummaryCard(primary),
                      _buildCategoryBreakdown(primary),
                      const SizedBox(height: 4),
                      // Stack all views so height never changes — no jumping
                      ClipRect(
                        child: Stack(
                          children: [
                            _fadeView(_buildListContent, 0),
                            _fadeView(_buildCalendarView, 1),
                            _fadeView(_buildChartView, 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
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
          floatingActionButton: BounceTap(
            onTap: _addRecord,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BounceTap(
            onTap: _previousMonth,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_left),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.15, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
            child: Text(
              _ym(_year, _month),
              key: ValueKey('${_year}_$_month'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          BounceTap(
            onTap: _nextMonth,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Color primary) {
    final balance = _monthlyIncome - _monthlyExpense;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  S.t(context, 'income'),
                  _monthlyIncome,
                  Colors.greenAccent,
                  onTap:
                      () =>
                          _showTypeBreakdown(S.t(context, 'income'), 'income'),
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _summaryItem(
                  S.t(context, 'expense'),
                  _monthlyExpense,
                  Colors.red,
                  onTap:
                      () => _showTypeBreakdown(
                        S.t(context, 'expense'),
                        'expense',
                      ),
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _summaryItem(
                  S.t(context, 'balance'),
                  balance,
                  balance >= 0 ? Colors.greenAccent : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String label,
    double amount,
    Color color, {
    VoidCallback? onTap,
  }) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '$_cs${amount.toStringAsFixed(0)}',
            key: ValueKey(amount),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return BounceTap(onTap: onTap, child: child);
    }
    return child;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tab chips
              Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    S.t(context, 'category'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  _buildTabChip(S.t(context, 'expense'), 0, Colors.red),
                  const SizedBox(width: 6),
                  _buildTabChip(S.t(context, 'income'), 1, Colors.green),
                ],
              ),
              const SizedBox(height: 10),
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
      ),
    );
  }

  Widget _buildTabChip(String label, int index, Color color) {
    final selected = _catTabIndex == index;
    return BounceTap(
      onTap: () => setState(() => _catTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color:
              selected
                  ? color.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              selected ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : Colors.grey[500],
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
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
                      '$_cs${entry.value.toStringAsFixed(0)}',
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
                    '${S.t(context, 'total')} $_cs${total.toStringAsFixed(0)}',
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
              ...dayRecords.map((r) => _buildRecordRow(r)),
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

  Widget _buildListContent() {
    if (_records.isEmpty) {
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

    final daily = _groupByDay(_records);
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
          key: ValueKey('${_year}_${_month}_$dateStr'),
          builder:
              (ctx, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - val)),
                  child: child,
                ),
              ),
          child: Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${S.t(context, 'calendar_date').replaceAll('%m', date.month.toString()).replaceAll('%d', date.day.toString())} ${S.t(context, 'calendar_week').replaceAll('%s', dayNames[date.weekday - 1])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (dayIncome > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    '${S.t(context, 'income')} $_cs${dayIncome.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ),
                              if (dayExpense > 0)
                                Text(
                                  '${S.t(context, 'expense')} $_cs${dayExpense.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[100],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '$_cs${(dayIncome - dayExpense).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              (dayIncome - dayExpense) >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dayRecords.map((r) => _buildRecordRow(r)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _fadeView(Widget Function() builder, int mode) {
    return AnimatedOpacity(
      opacity: _viewMode == mode ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(ignoring: _viewMode != mode, child: builder()),
    );
  }

  Widget _buildCalendarView() {
    // Build day → {expense, income} map
    final dayMap = <int, double>{};
    final dayIncomeMap = <int, double>{};
    for (final r in _records) {
      final d = DateTime.parse(r.date).day;
      if (r.type == 'expense') {
        dayMap[d] = (dayMap[d] ?? 0) + r.amount;
      } else {
        dayIncomeMap[d] = (dayIncomeMap[d] ?? 0) + r.amount;
      }
    }

    final now = DateTime.now();
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    // weekday: 1=Mon ... 7=Sun
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

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -50) {
            _nextMonth();
          } else if (details.primaryVelocity! > 50) {
            _previousMonth();
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Padding(
          key: ValueKey('$_year-$_month'),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Column(
            children: [
              // Weekday headers
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
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 4),
              // Day grid
              ...List.generate((startWeekday - 1 + daysInMonth + 6) ~/ 7, (
                row,
              ) {
                return Row(
                  children: List.generate(7, (col) {
                    final day = row * 7 + col - startWeekday + 2;
                    if (day < 1 || day > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 72));
                    }

                    final expense = dayMap[day];
                    final income = dayIncomeMap[day];
                    final isToday =
                        _year == now.year &&
                        _month == now.month &&
                        day == now.day;
                    final hasRecord = expense != null || income != null;

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: hasRecord ? () => _showDayDetail(day) : null,
                        child: Container(
                          height: 72,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color:
                                isToday
                                    ? primary.withValues(alpha: 0.1)
                                    : hasRecord
                                    ? Colors.grey.withValues(alpha: 0.04)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                isToday
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
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                ),
                              ),
                              if (expense != null)
                                Text(
                                  '-$expense',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red[200],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (income != null)
                                Text(
                                  '+$income',
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartView() {
    if (_chartData.isEmpty) {
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

    final maxVal = _chartData.fold<double>(0, (m, d) {
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
    final chartAreaH = chartTotalH - bottomLabelH;
    final n = _chartData.length;
    const barGroupW = 56.0;
    const barW = 16.0;
    const barGap = 4.0;
    final totalContentW = yLabelW + n * barGroupW;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    S.t(context, 'monthly_comparison'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  _chartLegend(Colors.green, S.t(context, 'income')),
                  const SizedBox(width: 12),
                  _chartLegend(Colors.red, S.t(context, 'expense')),
                ],
              ),
              const SizedBox(height: 20),
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
                            // ── Y-axis labels + grid lines ──
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

                            // ── Y-axis line ──
                            Positioned(
                              left: yLabelW,
                              top: 0,
                              bottom: bottomLabelH,
                              child: Container(
                                width: 1,
                                color: Colors.grey.withAlpha(80),
                              ),
                            ),

                            // ── Bars (flat, no nested Stack) ──
                            ..._chartData.asMap().entries.expand((entry) {
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
                              final maxBarH =
                                  incomeH > expenseH ? incomeH : expenseH;
                              final children = <Widget>[];

                              // Income bar
                              if (d.income > 0) {
                                children.add(
                                  Positioned(
                                    bottom: bottomLabelH,
                                    left:
                                        gl + barGroupW / 2 - barW - barGap / 2,
                                    width: barW,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        'inc_${idx}_${_year}_$_month',
                                      ),
                                      tween: Tween(begin: 0.0, end: incomeH),
                                      duration: Duration(
                                        milliseconds: 500 + idx * 60,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder:
                                          (ctx, h, _) => BounceTap(
                                            onTap:
                                                () => _showMonthDetail(
                                                  d.label,
                                                  'income',
                                                  d.income,
                                                ),
                                            child: Container(
                                              height: h,
                                              decoration: BoxDecoration(
                                                color: Colors.green[400],
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
                              // Expense bar
                              if (d.expense > 0) {
                                children.add(
                                  Positioned(
                                    bottom: bottomLabelH,
                                    left: gl + barGroupW / 2 + barGap / 2,
                                    width: barW,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        'exp_${idx}_${_year}_$_month',
                                      ),
                                      tween: Tween(begin: 0.0, end: expenseH),
                                      duration: Duration(
                                        milliseconds: 500 + idx * 60,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder:
                                          (ctx, h, _) => BounceTap(
                                            onTap:
                                                () => _showMonthDetail(
                                                  d.label,
                                                  'expense',
                                                  d.expense,
                                                ),
                                            child: Container(
                                              height: h,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
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
                              // Amount label
                              if (d.income > 0 || d.expense > 0) {
                                children.add(
                                  Positioned(
                                    bottom: bottomLabelH + maxBarH + 3,
                                    left: gl,
                                    width: barGroupW,
                                    child: Text(
                                      '$_cs${(d.income + d.expense).toInt()}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[500],
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              // Month label
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
    List<Record> filtered = [];

    Future<void> loadData() async {
      final records = await _db.getRecordsByMonth(year, month);
      filtered = records.where((r) => r.type == type).toList();
    }

    await loadData();
    if (!mounted) return;

    final catList = type == 'expense' ? expenseCategories : incomeCategories;
    final color = type == 'expense' ? Colors.red : Colors.green;

    // Aggregate by category
    final totals = <String, double>{};
    double total = 0;
    for (final r in filtered) {
      totals[r.category] = (totals[r.category] ?? 0) + r.amount;
      total += r.amount;
    }
    final sorted =
        totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) return;
    await showModalBottomSheet(
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
                    _ym(year, month),
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
                    '${S.t(context, 'total')} $_cs${total.toStringAsFixed(0)}',
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
                                LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(ctx).colorScheme.primary,
                                  ),
                                  minHeight: 4,
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
                            '$_cs${entry.value.toStringAsFixed(0)}',
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

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  void _showDayDetail(int day) {
    final dayRecords =
        _records.where((r) => DateTime.parse(r.date).day == day).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final dayIncome = dayRecords
            .where((r) => r.type == 'income')
            .fold(0.0, (s, r) => s + r.amount);
        final dayExpense = dayRecords
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
                S
                    .t(context, 'calendar_date')
                    .replaceAll('%m', _month.toString())
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
                    '${S.t(context, 'income')} $_cs${dayIncome.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${S.t(context, 'expense')} $_cs${dayExpense.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.red[200]),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${S.t(context, 'balance')} $_cs${(dayIncome - dayExpense).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          (dayIncome - dayExpense) >= 0
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              ...dayRecords.map((r) => _buildRecordRow(r)),
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

  Widget _buildRecordRow(Record r) {
    final cat = _catInfo(r);
    return Dismissible(
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
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(S.t(ctx, 'confirm_delete')),
                content: Text(S.t(ctx, 'confirm_delete_body')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(S.t(ctx, 'cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      S.t(ctx, 'delete'),
                      style: TextStyle(color: Colors.red),
                    ),
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
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editRecord(r),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
                      categoryDisplayName(r.category, _lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        if (r.date.isNotEmpty && r.time.isNotEmpty)
                          Text(
                            '${_d(r.date)} ${r.time}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                            maxLines: 1,
                          ),
                        if ((r.date.isNotEmpty || r.time.isNotEmpty) &&
                            r.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        if (r.note.isNotEmpty)
                          Expanded(
                            child: Text(
                              r.note,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${r.type == "expense" ? "-" : "+"}$_cs${r.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: r.type == 'expense' ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search helpers ──
  // Feedback animation overlay
  Widget _buildFeedback() {
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
                  // Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
