import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/utils/strings.dart';

void main() {
  group('S.tl()', () {
    test('returns Chinese translation for zh language', () {
      expect(S.tl('zh', 'settings'), equals('设置'));
      expect(S.tl('zh', 'income'), equals('收入'));
      expect(S.tl('zh', 'expense'), equals('支出'));
      expect(S.tl('zh', 'save'), equals('保存'));
    });

    test('returns English translation for en language', () {
      expect(S.tl('en', 'settings'), equals('Settings'));
      expect(S.tl('en', 'income'), equals('Income'));
      expect(S.tl('en', 'expense'), equals('Expense'));
      expect(S.tl('en', 'save'), equals('Save'));
    });

    test('falls back to Chinese for unknown language', () {
      expect(S.tl('ja', 'settings'), equals('设置'));
    });

    test('returns the key itself when translation is missing', () {
      expect(S.tl('en', 'nonexistent_key_xyz'), equals('nonexistent_key_xyz'));
    });

    test('returns Chinese translation for unknown language when key exists', () {
      expect(S.tl('fr', 'income'), equals('收入'));
    });
  });
}
