import 'package:nitmgpt/models/record.dart';

bool notificationMatchesSearch(Record record, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  bool contains(String? value) =>
      value != null && value.toLowerCase().contains(normalized);

  return contains(record.notificationTitle) ||
      contains(record.notificationText) ||
      contains(record.appName);
}
