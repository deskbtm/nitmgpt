import 'package:nitmgpt/services/device_apps.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:realm/realm.dart';

/// Seeds preview records on the home page when the database is empty.
const bool kSeedHomeMockData = true;

class HomeMockData {
  HomeMockData._();

  static const mockPackageNames = [
    'com.nitmgpt.mock.wechat',
    'com.nitmgpt.mock.shopping',
    'com.nitmgpt.mock.news',
  ];

  static const _apps = [
    ('com.nitmgpt.mock.wechat', 'WeChat'),
    ('com.nitmgpt.mock.shopping', 'Shopping'),
    ('com.nitmgpt.mock.news', 'News'),
  ];

  static bool isMockPackage(String packageName) {
    return mockPackageNames.contains(packageName);
  }

  static ApplicationWithIcon applicationFor(String packageName) {
    for (final app in _apps) {
      if (app.$1 == packageName) {
        return ApplicationWithIcon(
          appName: app.$2,
          packageName: app.$1,
          systemApp: false,
        );
      }
    }
    return ApplicationWithIcon(
      appName: packageName,
      packageName: packageName,
      systemApp: false,
    );
  }

  static void mergeMockAppsInto(Map<String, ApplicationWithIcon> map) {
    if (!kSeedHomeMockData || !hasMockRecords()) return;
    for (final packageName in mockPackageNames) {
      map.putIfAbsent(packageName, () => applicationFor(packageName));
    }
  }

  static bool hasMockRecords() {
    if (!kSeedHomeMockData) return false;
    for (final packageName in mockPackageNames) {
      if (realm
          .query<RecordedApp>('packageName == \$0', [packageName])
          .isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static const _entries = [
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Flash sale ending soon',
      body: 'Tap now to claim your limited-time coupon before it expires.',
      ad: 0.94,
      spam: 0.12,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Mom',
      body: 'Are you home for dinner tonight?',
      ad: 0.03,
      spam: 0.01,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Free coins waiting',
      body: 'Open the app and collect 500 bonus coins in one tap.',
      ad: 0.88,
      spam: 0.22,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Project standup',
      body: 'Reminder: daily sync starts in 15 minutes.',
      ad: 0.02,
      spam: 0.04,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'You won a prize',
      body: 'Congratulations! Verify your account to receive the reward.',
      ad: 0.91,
      spam: 0.76,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Alex',
      body: 'Sent you the APK link from yesterday.',
      ad: 0.05,
      spam: 0.08,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Install now for cashback',
      body: 'New users get instant cashback on the first order.',
      ad: 0.86,
      spam: 0.18,
    ),
    (
      package: 'com.nitmgpt.mock.wechat',
      title: 'Weekend hiking',
      body: 'Meet at the south gate at 8:30 AM.',
      ad: 0.01,
      spam: 0.02,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Order shipped',
      body: 'Your package left the warehouse and is on the way.',
      ad: 0.06,
      spam: 0.03,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Limited voucher inside',
      body: 'Spend 99 get 30 off — today only.',
      ad: 0.92,
      spam: 0.15,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Price drop alert',
      body: 'An item in your cart is now 18% cheaper.',
      ad: 0.24,
      spam: 0.05,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Spin to win',
      body: 'Daily lucky draw is live. Tap to participate.',
      ad: 0.89,
      spam: 0.31,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Delivery delayed',
      body: 'Heavy rain may delay arrival by about 2 hours.',
      ad: 0.04,
      spam: 0.02,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Clearance event',
      body: 'Thousands of items up to 70% off this week.',
      ad: 0.79,
      spam: 0.11,
    ),
    (
      package: 'com.nitmgpt.mock.shopping',
      title: 'Refund completed',
      body: 'The refund has been sent back to your wallet.',
      ad: 0.02,
      spam: 0.01,
    ),
    (
      package: 'com.nitmgpt.mock.news',
      title: 'Morning briefing',
      body: 'Top headlines: markets, weather, and local transit updates.',
      ad: 0.08,
      spam: 0.03,
    ),
    (
      package: 'com.nitmgpt.mock.news',
      title: 'Hot trending now',
      body: 'See what everyone is reading in your city today.',
      ad: 0.42,
      spam: 0.09,
    ),
    (
      package: 'com.nitmgpt.mock.news',
      title: 'Breaking: tech launch',
      body: 'A major phone maker announced a new device lineup.',
      ad: 0.11,
      spam: 0.04,
    ),
    (
      package: 'com.nitmgpt.mock.news',
      title: 'Earn points by reading',
      body: 'Open 3 articles to unlock bonus rewards.',
      ad: 0.83,
      spam: 0.27,
    ),
    (
      package: 'com.nitmgpt.mock.news',
      title: 'Live score update',
      body: 'Final quarter highlights are ready to watch.',
      ad: 0.15,
      spam: 0.05,
    ),
  ];

  static Future<bool> seedIfEmpty({
    required void Function(ApplicationWithIcon app) registerApp,
  }) async {
    if (!kSeedHomeMockData) return false;
    if (realm.all<Record>().isNotEmpty) return false;

    final appNames = {
      for (final app in _apps) app.$1: app.$2,
    };

    for (final app in _apps) {
      registerApp(applicationFor(app.$1));
    }

    final now = DateTime.now();
    final recordsByPackage = <String, List<Record>>{};

    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final createdAt = now.subtract(Duration(minutes: i * 17 + 3));
      final record = Record(
        ObjectId(),
        isAd: entry.ad >= 0.7,
        adProbability: entry.ad,
        isSpam: entry.spam >= 0.7,
        spamProbability: entry.spam,
        packageName: entry.package,
        appName: appNames[entry.package],
        notificationTitle: entry.title,
        notificationText: entry.body,
        timestamp: createdAt.millisecondsSinceEpoch,
        createTime: createdAt,
        uid: 'mock-$i',
        notificationKey: 'mock-key-$i',
      );
      recordsByPackage.putIfAbsent(entry.package, () => []).add(record);
    }

    await realm.writeAsync(() {
      for (final package in recordsByPackage.keys) {
        realm.add(
          RecordedApp(
            ObjectId(),
            package,
            records: recordsByPackage[package]!,
          ),
        );
      }
    });

    return true;
  }
}
