import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/state/notification_search_helpers.dart';
import 'package:realm/realm.dart';

void main() {
  group('notificationMatchesSearch', () {
    Record record({
      String? title,
      String? text,
      String? appName,
    }) {
      return Record(
        ObjectId(),
        notificationTitle: title,
        notificationText: text,
        appName: appName,
        packageName: 'com.example.app',
      );
    }

    test('matches title, body, and app name case-insensitively', () {
      final sample = record(
        title: 'Flash Sale',
        text: 'Limited time offer',
        appName: 'Shopping',
      );

      expect(notificationMatchesSearch(sample, 'flash'), isTrue);
      expect(notificationMatchesSearch(sample, 'OFFER'), isTrue);
      expect(notificationMatchesSearch(sample, 'shop'), isTrue);
      expect(notificationMatchesSearch(sample, 'wallet'), isFalse);
    });

    test('returns false for blank query', () {
      final sample = record(title: 'Hello');

      expect(notificationMatchesSearch(sample, ''), isFalse);
      expect(notificationMatchesSearch(sample, '   '), isFalse);
    });
  });
}
