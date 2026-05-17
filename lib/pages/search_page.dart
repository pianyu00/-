import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/record.dart';
import '../models/categories.dart';
import '../providers/app_settings_provider.dart';
import '../utils/strings.dart';
import 'add_record_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Record> _results = [];
  bool _searching = false;

  String get _cs => context.read<AppSettingsProvider>().currencySymbol;
  String _d(String dateStr) {
    final fmt = context.read<AppSettingsProvider>().dateFormat;
    if (fmt == 'yyyy-MM-dd') return dateStr;
    try {
      return DateFormat(fmt).format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    // Immediate UI rebuild for actions (clear button)
    setState(() {});
    _debounce?.cancel();
    if (text.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _searching = true;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _db.searchRecords(text);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 36,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: S.t(context, 'search_hint'),
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_searching && _results.isEmpty) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final r = _results[i];
        final cat = _catInfo(r);
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.08)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final result = await Navigator.push<Record>(
                context,
                MaterialPageRoute(
                    builder: (_) => AddRecordPage(record: r)),
              );
              if (result != null) {
                await _db.updateRecord(result);
                if (mounted) Navigator.pop(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cat?.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat?.icon ?? Icons.help_outline,
                        color: cat?.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.category,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: r.type == 'expense'
                                    ? Colors.red.withValues(
                                        alpha: 0.08)
                                    : Colors.green.withValues(
                                        alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.date.isNotEmpty
                                    ? _d(r.date)
                                    : '',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: r.type == 'expense'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (r.note.isNotEmpty || r.time.isNotEmpty)
                          Text(
                            '${r.note.isNotEmpty ? r.note : ''}${r.note.isNotEmpty && r.time.isNotEmpty ? ' · ' : ''}${r.time.isNotEmpty ? r.time : ''}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.type == "expense" ? "-" : "+"}$_cs${r.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: r.type == 'expense'
                          ? Colors.red
                          : Colors.green,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.search_rounded,
                size: 32,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 14),
          Text(S.t(context, 'search_empty_title'),
              style: TextStyle(fontSize: 15, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text(S.t(context, 'search_empty_hint'),
              style: TextStyle(fontSize: 12, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.search_off_rounded,
                size: 32, color: Colors.grey.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 14),
          Text(S.t(context, 'search_no_results'),
              style: TextStyle(fontSize: 15, color: Colors.grey[400])),
        ],
      ),
    );
  }

  CategoryInfo? _catInfo(Record r) {
    final list = r.type == 'expense' ? expenseCategories : incomeCategories;
    for (final c in list) {
      if (c.name == r.category) return c;
    }
    return null;
  }
}
