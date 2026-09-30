import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/calorie_card_figures.dart';

void main() {
  group('CalorieCardFigures.fromTotals', () {
    test('truncates calories left after subtracting intake', () {
      // 2000.2 - 100.9 = 1899.3. The card prints 1899. Truncating the
      // goal and the intake first, then subtracting, prints 1900.
      final figures = CalorieCardFigures.fromTotals(
        daily: 2000.2,
        supplied: 100.9,
        burned: 50.9,
      );

      expect(figures.supplied, 100);
      expect(figures.burned, 50);
      expect(figures.goal, 2000);
      expect(figures.shown, 1899);
      expect(figures.isOver, isFalse);
      expect(figures.goal - figures.supplied, 1900);
    });

    test('an overrun is the truncated absolute difference', () {
      // 2100.6 - 2000.4 = 100.2, printed as 100 over and 2100 eaten.
      final figures = CalorieCardFigures.fromTotals(
        daily: 2000.4,
        supplied: 2100.6,
        burned: 0,
      );

      expect(figures.isOver, isTrue);
      expect(figures.shown, 100);
      expect(figures.supplied, 2100);
    });

    test('being over by a fraction still flags the day as over', () {
      final figures = CalorieCardFigures.fromTotals(
        daily: 2000,
        supplied: 2000.4,
        burned: 0,
      );

      expect(figures.isOver, isTrue);
      expect(figures.shown, 0);
    });

    test('a negative intake caps the center at the goal', () {
      final figures = CalorieCardFigures.fromTotals(
        daily: 2000.6,
        supplied: -10.4,
        burned: 0,
      );

      expect(figures.shown, 2000);
      expect(figures.supplied, -10);
      expect(figures.isOver, isFalse);
    });
  });
}
