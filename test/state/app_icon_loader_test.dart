import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/state/app_icon_loader.dart';

void main() {
  group('orderPackagesForIconLoad', () {
    test('places priority packages first without duplicates', () {
      final ordered = orderPackagesForIconLoad(
        allPackages: const ['b', 'a', 'c', 'd'],
        priorityPackages: const ['c', 'a', 'c'],
      );

      expect(ordered, ['c', 'a', 'b', 'd']);
    });

    test('ignores unknown priority packages', () {
      final ordered = orderPackagesForIconLoad(
        allPackages: const ['b', 'a'],
        priorityPackages: const ['missing', 'a'],
      );

      expect(ordered, ['a', 'b']);
    });
  });
}
