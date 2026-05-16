import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/record.dart';
import '../models/categories.dart';
import '../utils/strings.dart';
import '../widgets/bounce_tap.dart';

class AddRecordPage extends StatefulWidget {
  final Record? record;

  const AddRecordPage({super.key, this.record});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  String _category = '餐饮';
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _amountController.text = r.amount.toString();
      _type = r.type;
      _category = r.category;
      _selectedDate = DateTime.parse(r.date);
      _noteController.text = r.note;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<CategoryInfo> get _categories =>
      _type == 'expense' ? expenseCategories : incomeCategories;
  String get _lang => AccountBookApp.of(context)?.language ?? 'zh';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record != null ? S.t(context, 'edit_record_title') : S.t(context, 'add_record_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期 — 最上面
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),

              // 金额输入
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: S.t(context, 'amount'),
                  prefixText: '${AccountBookApp.of(context)?.currencySymbol ?? '¥'} ',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return S.t(context, 'amount_required');
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return S.t(context, 'amount_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 收入/支出切换
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton('expense', S.t(context, 'expense'), Icons.trending_down,
                        Colors.red),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeButton('income', S.t(context, 'income'), Icons.trending_up,
                        Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 分类
              Text(
                S.t(context, 'category'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((cat) {
                  final selected = _category == cat.name;
                  return BounceTap(
                    onTap: () => setState(() => _category = cat.name),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: selected
                                ? Border.all(color: cat.color, width: 2)
                                : null,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(categoryDisplayName(cat.name, _lang),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? cat.color : Colors.grey[600],
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 备注
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: S.t(context, 'note_optional'),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.record != null ? S.t(context, 'save_changes') : S.t(context, 'save'),
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
      String type, String label, IconData icon, Color color) {
    final selected = _type == type;
    return BounceTap(
      onTap: () {
        setState(() {
          _type = type;
          if (!_categories.any((c) => c.name == _category)) {
            _category = _categories.first.name;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey[600],
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
      initialDate:
          _selectedDate.isAfter(now) ? now : _selectedDate,
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

    // 拒绝未来的日期
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
