import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isPersistent is true when isOngoing is true', () {
    final event = NotificationEvent(isOngoing: true);
    expect(event.isPersistent, isTrue);
    expect(isPersistentNotification(event), isTrue);
  });

  test('isPersistent falls back to FLAG_ONGOING_EVENT on flags', () {
    final event = NotificationEvent(flags: NotificationEvent.flagOngoingEvent);
    expect(event.isPersistent, isTrue);
  });

  test('isPersistent is false for normal notifications', () {
    final event = NotificationEvent(isOngoing: false, flags: 0);
    expect(event.isPersistent, isFalse);
  });
}
