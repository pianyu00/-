import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/models/categories.dart';

void main() {
  group('categoryDisplayName()', () {
    test('returns Chinese name for zh language', () {
      expect(categoryDisplayName('餐饮', 'zh'), equals('餐饮'));
      expect(categoryDisplayName('工资', 'zh'), equals('工资'));
      expect(categoryDisplayName('交通', 'zh'), equals('交通'));
    });

    test('returns English name for en language', () {
      expect(categoryDisplayName('餐饮', 'en'), equals('Dining'));
      expect(categoryDisplayName('工资', 'en'), equals('Salary'));
      expect(categoryDisplayName('交通', 'en'), equals('Transport'));
    });

    test('returns Chinese name for unknown category', () {
      expect(categoryDisplayName('未知分类', 'en'), equals('未知分类'));
    });
  });

  group('expenseCategories', () {
    test('contains expected categories', () {
      final names = expenseCategories.map((c) => c.name).toList();
      expect(names, contains('餐饮'));
      expect(names, contains('交通'));
      expect(names, contains('购物'));
    });

    test('all categories have icons and colors', () {
      for (final cat in expenseCategories) {
        expect(cat.icon, isNotNull);
        expect(cat.color, isNotNull);
      }
    });
  });

  group('incomeCategories', () {
    test('contains expected categories', () {
      final names = incomeCategories.map((c) => c.name).toList();
      expect(names, contains('工资'));
      expect(names, contains('兼职'));
    });

    test('all categories have icons and colors', () {
      for (final cat in incomeCategories) {
        expect(cat.icon, isNotNull);
        expect(cat.color, isNotNull);
      }
    });
  });
}
