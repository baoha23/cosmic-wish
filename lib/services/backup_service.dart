import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wish_history_entry.dart';
import 'history_service.dart';

class BackupService {
  BackupService({HistoryService? historyService})
    : _history = historyService ?? HistoryService();

  final HistoryService _history;

  /// Export all history as JSON file, then open share sheet.
  Future<File> exportToFile() async {
    final entries = await _history.loadAll();
    final payload = {
      'version': 1,
      'app': 'cosmic_wish',
      'exported_at': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/cosmic_wish_history_$ts.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file;
  }

  Future<void> exportAndShare() async {
    final file = await exportToFile();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Cosmic Wish - Lịch sử điều ước',
      ),
    );
  }

  /// Pick a JSON file, parse it, merge with existing history.
  /// Returns number of entries imported.
  Future<int> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return 0;
    final path = result.files.first.path;
    if (path == null) return 0;
    return importFromFile(File(path));
  }

  Future<int> importFromFile(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file format');
    }
    final entries = data['entries'];
    if (entries is! List) {
      throw const FormatException('Missing entries list');
    }
    final parsed = <WishHistoryEntry>[];
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        parsed.add(WishHistoryEntry.fromJson(raw));
      } catch (_) {
        // Skip invalid entries
      }
    }
    // Batch insert — single read + single write regardless of N.
    return _history.insertAll(parsed);
  }
}
