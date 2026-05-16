import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _platform = MethodChannel('com.example.account_book/file');

/// Save [content] as a CSV file to the public Downloads directory.
/// Returns the saved file path.
Future<String> saveCsvToDownloads(String fileName, String content) async {
  try {
    final path = await _platform.invokeMethod<String>('saveToDownloads', {
      'name': fileName,
      'content': content,
    });
    if (path != null) return path;
  } catch (_) {
    // Fallback to app documents directory
  }
  // Fallback for non-Android or if platform channel fails
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}
