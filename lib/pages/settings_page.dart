import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/app_themes.dart';
import '../providers/app_settings_provider.dart';
import '../utils/file_helper.dart';
import '../utils/strings.dart';
import '../widgets/bounce_tap.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _db = DatabaseHelper();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings'))),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (ctx, val, child) => Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: child,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
          _section(S.t(context, 'data_management')),
          _card([
            _exportTile(theme, app),
            _importTile(theme),
            _dedupTile(theme),
            _clearTile(theme),
          ]),
          const SizedBox(height: 20),
          _section(S.t(context, 'theme_appearance')),
          _card([
            _darkModeTile(theme, app),
            _themeTile(theme, app),
          ]),
          const SizedBox(height: 20),
          _section(S.t(context, 'preferences')),
          _card([
            _dateFormatTile(app, theme),
            _currencyTile(app, theme),
            _languageTile(app, theme),
          ]),
          const SizedBox(height: 20),
          _aboutTile(theme),
        ],
      ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500])),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    Divider(height: 1, indent: 56, color: Colors.grey[100]),
                ])
            .toList(),
      ),
    );
  }

  /// Custom toggle row: two buttons with consistent sizing and bounce tap.
  Widget _toggleOption<T>({
    required List<T> values,
    required List<String> labels,
    required T selected,
    required ValueChanged<T> onChanged,
    required Color activeColor,
    bool equalWidth = false,
  }) {
    final buttons = List.generate(values.length, (i) {
      final sel = values[i] == selected;
      final btn = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: sel
              ? activeColor.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel
                ? activeColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Text(
          labels[i],
          style: TextStyle(
            fontSize: 13,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
            color: sel ? activeColor : Colors.grey[600],
          ),
        ),
      );
      final wrapped = BounceTap(
        onTap: () => onChanged(values[i]),
        child: btn,
      );
      return Padding(
        padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
        child: equalWidth ? Expanded(child: wrapped) : wrapped,
      );
    });
    return Row(
      mainAxisSize: equalWidth ? MainAxisSize.max : MainAxisSize.min,
      children: buttons,
    );
  }

  Widget _leading(IconData icon, Color color) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ── 数据管理 ──

  Widget _exportTile(ThemeData theme, AppSettingsProvider app) {
    final tile = ListTile(
      leading: _leading(Icons.file_download_outlined, theme.colorScheme.primary),
      title: Text(S.t(context, 'export_csv'), style: const TextStyle(fontSize: 15)),
      subtitle: Text(_exporting ? S.t(context, 'exporting') : S.t(context, 'export_csv_hint'),
          style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      trailing: _exporting
          ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: theme.colorScheme.primary))
          : Icon(Icons.chevron_right, color: Colors.grey[400]),
    );
    return _exporting
        ? tile
        : BounceTap(onTap: _exportCsv, child: tile);
  }

  Widget _importTile(ThemeData theme) {
    return BounceTap(
      onTap: _importCsv,
      child: ListTile(
        leading: _leading(Icons.file_upload_outlined, theme.colorScheme.primary),
        title: Text(S.t(context, 'import_csv'), style: const TextStyle(fontSize: 15)),
        subtitle: Text(S.t(context, 'import_csv_hint'),
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Widget _dedupTile(ThemeData theme) {
    return BounceTap(
      onTap: _dedupData,
      child: ListTile(
        leading: _leading(Icons.filter_alt_outlined, Colors.orange),
        title: Text(S.t(context, 'dedup_data'), style: const TextStyle(fontSize: 15)),
        subtitle: Text(S.t(context, 'dedup_data_hint'),
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _dedupData() async {
    final removed = await _db.removeDuplicates();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed > 0
              ? S.t(context, 'dedup_success').replaceAll('%d', removed.toString())
              : S.t(context, 'dedup_none'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportCsv() async {
    final app = context.read<AppSettingsProvider>();
    final lang = app.language;

    final result = await showDialog<_ExportRange>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DateRangeDialog(),
    );
    if (result == null) return;

    setState(() => _exporting = true);
    try {
      String csv;
      String dateSuffix;
      if (result.start != null && result.end != null) {
        csv = await _db.exportCsv(
          lang: lang,
          startDate: result.start,
          endDate: result.end,
        );
        dateSuffix = '${result.start}_${result.end}';
      } else {
        csv = await _db.exportCsv(lang: lang);
        dateSuffix = 'all';
      }
      final name =
          '轻记账_$dateSuffix.csv';
      final path = await saveCsvToDownloads(name, csv);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.t(context, 'export_csv')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (ctx, val, _) => Transform.scale(
                    scale: val,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('${S.t(context, 'export_success')}\n$path',
                    textAlign: TextAlign.center),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(S.t(context, 'ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.t(context, 'export_failed')}$e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importCsv() async {
    // Confirm before importing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t(ctx, 'import_csv')),
        content: Text(S.t(ctx, 'import_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t(ctx, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t(ctx, 'ok')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${S.t(context, 'import_failed')}: 无法读取文件'),
                behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }

      final csv = utf8.decode(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t(context, 'importing')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final count = await _db.importFromCsv(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.t(ctx, 'import_csv')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  S.t(context, 'import_success').replaceAll('%d', count.toString()),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(S.t(ctx, 'ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.t(context, 'import_failed')}: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _clearTile(ThemeData theme) {
    return BounceTap(
      onTap: _confirmClear,
      child: ListTile(
        leading: _leading(Icons.delete_forever_outlined, Colors.red),
        title: Text(S.t(context, 'clear_data'), style: const TextStyle(fontSize: 15)),
        subtitle: Text(S.t(context, 'clear_data_hint'),
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t(context, 'clear_confirm_title')),
        content: Text(S.t(context, 'clear_confirm_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.t(context, 'cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t(context, 'clear'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t(context, 'cleared')),
              behavior: SnackBarBehavior.floating),
        );
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ── 主题与外观 ──

  Widget _darkModeTile(ThemeData theme, AppSettingsProvider app) {
    final isDark = app.themeMode == ThemeMode.dark;
    return ListTile(
      leading: _leading(
          isDark ? Icons.dark_mode : Icons.light_mode,
          theme.colorScheme.primary),
      title: Text(S.t(context, 'dark_mode'), style: const TextStyle(fontSize: 15)),
      trailing: _toggleOption<bool>(
        values: const [false, true],
        labels: [S.t(context, 'light'), S.t(context, 'dark')],
        selected: isDark,
        onChanged: (v) => app.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _themeTile(ThemeData theme, AppSettingsProvider app) {
    return BounceTap(
      onTap: () => _showThemePicker(app),
      child: ListTile(
        leading: _leading(Icons.palette_outlined, theme.colorScheme.primary),
        title: Text(S.t(context, 'theme_color'), style: const TextStyle(fontSize: 15)),
        subtitle: Text(appThemes[app.themeIndex].name,
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: appThemes[app.themeIndex].seedColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(AppSettingsProvider app) {
    showDialog(
      context: context,
      builder: (ctx) => _ThemePickerContent(app: app),
    );
  }

  // ── 基础偏好 ──

  Widget _dateFormatTile(AppSettingsProvider app, ThemeData theme) {
    const formats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy'];
    return ListTile(
      leading: _leading(Icons.date_range, theme.colorScheme.primary),
      title: Text(S.t(context, 'date_format'), style: const TextStyle(fontSize: 15)),
      subtitle: Text(app.dateFormat,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      trailing: DropdownButton<String>(
        value: app.dateFormat,
        underline: const SizedBox.shrink(),
        items: formats.map((f) => DropdownMenuItem(
          value: f,
          child: Text(f, style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: (v) {
          if (v != null) app.changeDateFormat(v);
        },
      ),
    );
  }

  Widget _currencyTile(AppSettingsProvider app, ThemeData theme) {
    return StatefulBuilder(
      builder: (context, localSetState) {
        return ListTile(
          leading: _leading(Icons.monetization_on_outlined, theme.colorScheme.primary),
          title: Text(S.t(context, 'currency_unit'), style: const TextStyle(fontSize: 15)),
          trailing: _toggleOption<String>(
            values: const ['¥', '\$'],
            labels: const ['¥ CNY', '\$ USD'],
            selected: app.currencySymbol,
            onChanged: (v) {
              app.changeCurrency(v);
              localSetState(() {});
            },
            activeColor: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _languageTile(AppSettingsProvider app, ThemeData theme) {
    return ListTile(
      leading: _leading(Icons.language, theme.colorScheme.primary),
      title: Text(S.t(context, 'language'), style: const TextStyle(fontSize: 15)),
      trailing: _toggleOption<String>(
        values: const ['zh', 'en'],
        labels: const ['中文', 'English'],
        selected: app.language,
        onChanged: (v) => app.changeLanguage(v),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  // ── 关于 ──

  Widget _aboutTile(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: BounceTap(
        onTap: () {
          Navigator.push(context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, a1, a2) => const AboutPage(),
                transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
              ));
        },
        child: ListTile(
          leading: _leading(Icons.info_outline, theme.colorScheme.primary),
          title: Text(S.t(context, 'about'), style: const TextStyle(fontSize: 15)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

/// Result from the date range dialog.
class _ExportRange {
  final String? start;
  final String? end;
  const _ExportRange(this.start, this.end);
}

/// Dialog to pick a date range for CSV export.
class _DateRangeDialog extends StatefulWidget {
  const _DateRangeDialog();

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  late String _fmt;

  @override
  void initState() {
    super.initState();
    _fmt = context.read<AppSettingsProvider>().dateFormat;
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate.isAfter(now) ? now : _startDate)
          : (_endDate.isAfter(now) ? now : _endDate),
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('zh'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _setPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      switch (preset) {
        case 'today':
          _startDate = now;
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat(_fmt);
    return AlertDialog(
      title: Text(S.t(context, 'export_select_range')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _setPreset('today'),
                  child: Text(S.t(context, 'today')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => _setPreset('month'),
                  child: Text(S.t(context, 'this_month')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => _setPreset('year'),
                  child: Text(S.t(context, 'this_year')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: Text('${S.t(context, 'start_date')}: ${fmt.format(_startDate)}'),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: () => _pickDate(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: Text('${S.t(context, 'end_date')}: ${fmt.format(_endDate)}'),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: () => _pickDate(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.t(context, 'cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _ExportRange(null, null));
          },
          child: Text(S.t(context, 'export_all')),
        ),
        FilledButton(
          onPressed: () {
            final start = DateFormat('yyyy-MM-dd').format(_startDate);
            final end = DateFormat('yyyy-MM-dd').format(_endDate);
            Navigator.pop(context, _ExportRange(start, end));
          },
          child: Text(S.t(context, 'export_range')),
        ),
      ],
    );
  }
}

/// Animated theme color picker dialog — pulses selected item, then exits with scale+fade.
class _ThemePickerContent extends StatefulWidget {
  final AppSettingsProvider app;
  const _ThemePickerContent({required this.app});

  @override
  State<_ThemePickerContent> createState() => _ThemePickerContentState();
}

class _ThemePickerContentState extends State<_ThemePickerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;
  late Animation<double> _dialogScaleAnim;
  late Animation<double> _dialogOpacityAnim;
  int? _animatingIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _dialogScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _dialogOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickColor(int index) {
    setState(() => _animatingIndex = index);
    _controller.forward().then((_) {
      widget.app.changeTheme(index);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, child) {
        final opacity = _dialogOpacityAnim.value;
        final scale = _dialogScaleAnim.value;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: AlertDialog(
        title: Text(S.t(context, 'pick_theme_color')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: appThemes.length,
            itemBuilder: (ctx, i) {
              final t = appThemes[i];
              final sel = i == widget.app.themeIndex;
              final isAnimating = _animatingIndex == i;
              final scale = isAnimating ? _pulseAnim.value : 1.0;

              return GestureDetector(
                onTap: () => _pickColor(i),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.seedColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: sel
                          ? Border.all(color: t.seedColor, width: 3)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon, color: t.seedColor, size: 28),
                        const SizedBox(height: 4),
                        Text(t.name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: t.seedColor)),
                        if (sel)
                          Icon(Icons.check, size: 16, color: t.seedColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ),
    );
  }
}
