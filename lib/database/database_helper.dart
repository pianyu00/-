import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'account_book.db');
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT DEFAULT '',
            note TEXT DEFAULT ''
          )
        ''');
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE records ADD COLUMN time TEXT DEFAULT ""',
          );
        }
        if (oldVersion < 3) {
          await _createIndexes(db);
        }
      },
    );
    // PRAGMAs must run outside onCreate/onUpgrade (they're in a transaction)
    await db.rawQuery("PRAGMA journal_mode=WAL");
    await db.rawQuery("PRAGMA synchronous=NORMAL");
    return db;
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_date ON records(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_type ON records(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_date_type ON records(date, type)',
    );
  }

  Future<int> insertRecord(Record record) async {
    final db = await database;
    return await db.insert('records', record.toMap()..remove('id'));
  }

  Future<int> updateRecord(Record record) async {
    final db = await database;
    return await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Record>> getRecordsByMonth(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final startDate = '$year-$monthStr-01';
    final endDate = '$year-$monthStr-31';

    final result = await db.query(
      'records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => Record.fromMap(map)).toList();
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final startDate = '$year-$monthStr-01';
    final endDate = '$year-$monthStr-31';

    final result = await db.rawQuery(
      '''
      SELECT type, SUM(amount) as total
      FROM records
      WHERE date >= ? AND date <= ?
      GROUP BY type
    ''',
      [startDate, endDate],
    );

    double income = 0;
    double expense = 0;
    for (var row in result) {
      if (row['type'] == 'income') {
        income = row['total'] as double;
      } else if (row['type'] == 'expense') {
        expense = row['total'] as double;
      }
    }
    return {'income': income, 'expense': expense};
  }

  Future<List<Record>> getAllRecords() async {
    final db = await database;
    final result = await db.query('records', orderBy: 'date DESC, id DESC');
    return result.map((map) => Record.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlySummaries(
    int year,
    int month,
    int count,
  ) async {
    final db = await database;
    final startMonth = DateTime(year, month - count + 1, 1);
    final startDate =
        '${startMonth.year}-${startMonth.month.toString().padLeft(2, '0')}-01';
    return await db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date) as month, type, SUM(amount) as total
      FROM records
      WHERE date >= ?
      GROUP BY month, type
      ORDER BY month ASC
    ''',
      [startDate],
    );
  }

  Future<List<Record>> getRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, id ASC',
    );
    return result.map((map) => Record.fromMap(map)).toList();
  }

  Future<List<Record>> searchRecords(String query) async {
    final db = await database;
    final term = '%$query%';
    final result = await db.query(
      'records',
      where: 'category LIKE ? OR note LIKE ? OR CAST(amount AS TEXT) LIKE ?',
      whereArgs: [term, term, term],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => Record.fromMap(map)).toList();
  }

  /// Returns file sizes in bytes for db, wal, shm.
  Future<Map<String, int>> getDbFileInfo() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'account_book.db');
    final info = <String, int>{};
    for (final ext in ['', '-wal', '-shm']) {
      final f = File('$path$ext');
      info[ext.isEmpty ? 'db' : ext.substring(1)] =
          await f.exists() ? await f.length() : 0;
    }
    return info;
  }

  /// Compact database: checkpoint + incremental vacuum.
  Future<void> compactDatabase() async {
    final db = await database;
    await db.rawQuery("PRAGMA wal_checkpoint(TRUNCATE)");
    // Reclaim free pages without rewriting the entire file
    final count = await db.rawQuery("PRAGMA freelist_count");
    if (count.isNotEmpty && count.first.values.first is int) {
      final pages = count.first.values.first as int;
      if (pages > 0) {
        await db.rawQuery("PRAGMA incremental_vacuum($pages)");
      }
    }
  }

  /// Parse and import records from CSV content (exported by [exportCsv]).
  /// Returns the number of records imported.
  /// Throws on parse error with a description.
  Future<int> importFromCsv(String csv) async {
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) throw Exception('CSV 文件为空或格式不正确');

    // Parse CSV line respecting quoted fields
    List<String> parseLine(String line) {
      final result = <String>[];
      var current = StringBuffer();
      var inQuotes = false;
      for (var i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (ch == ',' && !inQuotes) {
          result.add(current.toString().trim());
          current = StringBuffer();
        } else {
          current.write(ch);
        }
      }
      result.add(current.toString().trim());
      return result;
    }

    // Map Chinese/English type strings to internal type
    String parseType(String raw) {
      if (raw == '支出' || raw == 'Expense' || raw == 'expense') return 'expense';
      if (raw == '收入' || raw == 'Income' || raw == 'income') return 'income';
      throw Exception('无法识别的类型: $raw');
    }

    final db = await database;
    var count = 0;

    // Start from line 1 (skip header)
    for (var i = 1; i < lines.length; i++) {
      final cols = parseLine(lines[i]);
      if (cols.length < 4) continue;

      final record = Record(
        amount: double.tryParse(cols[3]) ?? 0,
        type: parseType(cols[1]),
        category: cols[2],
        date: cols[0],
        time: cols.length > 4 ? cols[4] : '',
        note: cols.length > 5 ? cols[5] : '',
      );
      await db.insert('records', record.toMap()..remove('id'));
      count++;
    }
    // Clean up any exact duplicates that may exist
    await removeDuplicates();
    return count;
  }

  /// Remove exact duplicate records (same type, category, amount, date, time, note),
  /// keeping only the row with the lowest id.
  Future<int> removeDuplicates() async {
    final db = await database;
    final result = await db.rawDelete('''
      DELETE FROM records WHERE id NOT IN (
        SELECT MIN(id) FROM records GROUP BY type, category, amount, date, time, note
      )
    ''');
    return result;
  }

  /// Delete all records from the database.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('records');
  }

  /// Generate CSV string (UTF-8 BOM) for all records (or a date range).
  /// [lang] is 'zh' or 'en' for localized column headers and type names.
  /// [startDate] and [endDate] in 'yyyy-MM-dd' format for range filtering.
  Future<String> exportCsv({
    String lang = 'zh',
    String? startDate,
    String? endDate,
  }) async {
    final records =
        (startDate != null && endDate != null)
            ? await getRecordsByDateRange(startDate, endDate)
            : await getAllRecords();
    final buf = StringBuffer();
    // BOM for Chinese Excel compatibility
    buf.write('﻿');
    if (lang == 'en') {
      buf.writeln('Date,Type,Category,Amount,Time,Note');
    } else {
      buf.writeln('日期,类型,分类,金额,时间,备注');
    }
    for (final r in records) {
      final type =
          r.type == 'expense'
              ? (lang == 'en' ? 'Expense' : '支出')
              : (lang == 'en' ? 'Income' : '收入');
      final note = r.note.replaceAll('"', '""');
      buf.writeln(
        '${r.date},$type,${r.category},${r.amount},${r.time},"$note"',
      );
    }
    return buf.toString();
  }
}
