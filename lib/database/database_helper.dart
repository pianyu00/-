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
    return await openDatabase(
      path,
      version: 2,
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE records ADD COLUMN time TEXT DEFAULT ""',
          );
        }
      },
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

  /// Compact database: checkpoint + VACUUM.
  Future<void> compactDatabase() async {
    final db = await database;
    await db.rawQuery("PRAGMA wal_checkpoint(TRUNCATE)");
    await db.execute('VACUUM');
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
