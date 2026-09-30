import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/calorie_card_figures.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';

void main() {
  group('CalorieWidgetSnapshot.fromHome', () {
    test('maps supplied intake and goal to the home card integers', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 180.4,
        goalKcal: 2000.6,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );

      expect(snapshot.hasData, isTrue);
      expect(snapshot.consumedKcal, 180);
      expect(snapshot.goalKcal, 2000);
      // 2000.6 - 180.4 = 1820.2, which the card prints as 1820.
      expect(snapshot.shownKcal, 1820);
      expect(snapshot.isOver, isFalse);
      expect(snapshot.dayId, '2026-09-23');
      expect(snapshot.toPayload(), {
        CalorieWidgetSnapshot.hasDataKey: '1',
        CalorieWidgetSnapshot.dayKey: '2026-09-23',
        CalorieWidgetSnapshot.offsetKey: '0',
        CalorieWidgetSnapshot.consumedKey: '180',
        CalorieWidgetSnapshot.burnedKey: '0',
        CalorieWidgetSnapshot.goalKey: '2000',
        CalorieWidgetSnapshot.shownKey: '1820',
        CalorieWidgetSnapshot.overKey: '0',
      });
    });

    test(
      'center matches the card when the parts would subtract differently',
      () {
        // 2000.2 - 100.9 = 1899.3, printed as 1899. Truncating each part
        // first yields 2000 - 100 = 1900.
        final snapshot = CalorieWidgetSnapshot.fromHome(
          consumedKcal: 100.9,
          goalKcal: 2000.2,
          burnedKcal: 50.9,
          offsetMinutes: 0,
          now: DateTime(2026, 9, 23, 13, 0),
        );
        final card = CalorieCardFigures.fromTotals(
          daily: 2000.2,
          supplied: 100.9,
          burned: 50.9,
        );

        expect(snapshot.consumedKcal, card.supplied);
        expect(snapshot.burnedKcal, card.burned);
        expect(snapshot.goalKcal, card.goal);
        expect(snapshot.shownKcal, card.shown);
        expect(snapshot.shownKcal, 1899);
        expect(snapshot.consumedKcal, 100);
        expect(snapshot.burnedKcal, 50);
        expect(snapshot.goalKcal - snapshot.consumedKcal, 1900);
      },
    );

    test('an overrun under one kilocalorie still counts as over', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 2000.4,
        goalKcal: 2000,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );

      expect(snapshot.isOver, isTrue);
      expect(snapshot.shownKcal, 0);
      expect(snapshot.toPayload()[CalorieWidgetSnapshot.overKey], '1');
      expect(snapshot.toPayload()[CalorieWidgetSnapshot.shownKey], '0');
    });

    test('burned kilocalories are the activity reduction', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 1800,
        goalKcal: 2200,
        burnedKcal: 250.6,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );
      final cleared = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 40,
        goalKcal: 0,
        burnedKcal: 80,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );
      final negative = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 100,
        goalKcal: 2000,
        burnedKcal: -20,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );

      expect(snapshot.burnedKcal, 250);
      expect(snapshot.toPayload()[CalorieWidgetSnapshot.burnedKey], '250');
      expect(negative.burnedKcal, -20);
      expect(cleared.burnedKcal, 0);
      expect(cleared.toPayload()[CalorieWidgetSnapshot.burnedKey], '0');
    });

    test('a zero goal is a placeholder, not a progress ring', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 40,
        goalKcal: 0,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 8, 0),
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.toPayload()[CalorieWidgetSnapshot.hasDataKey], '0');
      expect(snapshot.toPayload()[CalorieWidgetSnapshot.consumedKey], '0');
    });

    test('an out-of-range offset is treated as midnight', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 10,
        goalKcal: 2000,
        offsetMinutes: 24 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.offsetMinutes, 0);
      expect(snapshot.dayId, '2026-09-23');
    });
  });

  group('CalorieWidgetSnapshot logical day', () {
    test('a 04:00 boundary files 01:00 under the previous day', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 100,
        goalKcal: 2000,
        offsetMinutes: 4 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.dayId, '2026-09-22');
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 23, 2, 0)), isTrue);
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 23, 5, 0)), isFalse);
    });

    test('the next boundary is the following day at the offset', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 100,
        goalKcal: 2000,
        offsetMinutes: 4 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.nextBoundary(), DateTime(2026, 9, 23, 4, 0));
    });

    test('isCurrentAt follows DayBoundaryCalc for the stored offset', () {
      final now = DateTime(2026, 9, 23, 18, 30);
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 500,
        goalKcal: 2200,
        offsetMinutes: 0,
        now: now,
      );
      final logical = DayBoundaryCalc.logicalDayOfMinutes(now, 0);

      expect(snapshot.dayId, CalorieWidgetSnapshot.formatDayId(logical));
      expect(snapshot.isCurrentAt(now), isTrue);
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 24, 0, 5)), isFalse);
    });
  });
}
