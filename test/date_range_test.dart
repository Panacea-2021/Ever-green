import 'package:flutter_test/flutter_test.dart';
import 'package:evergreen/features/technicians/data/performance_provider.dart';

void main() {
  group('DateRange presets', () {
    test('Today covers only the current day', () {
      final now = DateTime(2026, 6, 15, 10, 0);
      final r = DateRange.fromPreset(RangePreset.today, now);
      expect(r.contains(DateTime(2026, 6, 15, 0, 0)), isTrue);
      expect(r.contains(DateTime(2026, 6, 15, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 6, 14, 23, 59)), isFalse);
      expect(r.contains(DateTime(2026, 6, 16, 0, 0)), isFalse);
    });

    test('This Week starts on Monday', () {
      // 2026-06-15 is a Monday.
      final monday = DateTime(2026, 6, 15, 12, 0);
      final r = DateRange.fromPreset(RangePreset.week, monday);
      expect(r.start, DateTime(2026, 6, 15, 0, 0));
      // A Wednesday in the same week is included.
      final wednesday = DateTime(2026, 6, 17, 12, 0);
      final rFromWed = DateRange.fromPreset(RangePreset.week, wednesday);
      expect(rFromWed.start, DateTime(2026, 6, 15, 0, 0));
      expect(rFromWed.contains(DateTime(2026, 6, 16)), isTrue);
    });

    test('This Month starts on the 1st', () {
      final now = DateTime(2026, 6, 20);
      final r = DateRange.fromPreset(RangePreset.month, now);
      expect(r.start, DateTime(2026, 6, 1, 0, 0));
      expect(r.contains(DateTime(2026, 6, 1)), isTrue);
      expect(r.contains(DateTime(2026, 5, 31, 23, 59)), isFalse);
    });

    test('custom range is inclusive of both endpoints', () {
      final r = DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      expect(r.contains(DateTime(2026, 1, 1, 0, 0)), isTrue);
      expect(r.contains(DateTime(2026, 1, 31, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 2, 1)), isFalse);
      expect(r.preset, RangePreset.custom);
    });

    test('contains(null) is false', () {
      final r = DateRange.fromPreset(RangePreset.month);
      expect(r.contains(null), isFalse);
    });

    test('summary shows preset label for presets', () {
      expect(DateRange.fromPreset(RangePreset.today).summary, 'Today');
      expect(DateRange.fromPreset(RangePreset.week).summary, 'This Week');
    });

    test('equality by start/end/preset', () {
      final a = DateRange.fromPreset(RangePreset.month, DateTime(2026, 6, 10));
      final b = DateRange.fromPreset(RangePreset.month, DateTime(2026, 6, 10));
      expect(a, b);
    });
  });
}
