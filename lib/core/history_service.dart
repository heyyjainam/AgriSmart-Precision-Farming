import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String id;
  final String type;
  final String result;
  final String detail;
  final String status;
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.result,
    required this.detail,
    required this.status,
    required this.timestamp,
  });

  String get formattedDate {
    final date = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$date/$month/$year · $hour:$minute';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'result': result,
    'detail': detail,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'],
    type: json['type'],
    result: json['result'],
    detail: json['detail'],
    status: json['status'] ?? 'Active',
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _storageKey = 'agrismart_history_v2';
  static const int _maxEntries = 50;

  Future<List<HistoryEntry>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => HistoryEntry.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistory(List<HistoryEntry> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (_) {}
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final history = await loadHistory();
    history.insert(0, entry);
    final trimmed = history.take(_maxEntries).toList();
    await saveHistory(trimmed);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
