/// Whole-number calories the home card prints in the ring.
///
/// The card truncates with [double.toInt] (toward zero). Calories left are
/// truncated after intake is subtracted from the goal. Truncating the goal
/// and the intake first, then subtracting, is a different number, and so is
/// rounding each figure before the subtraction. Either path drifts from the
/// card by one or two kilocalories.
class CalorieCardFigures {
  final int supplied;
  final int burned;
  final int goal;

  /// Absolute value printed in the center of the ring.
  final int shown;

  /// True when intake is past the goal, including by a fraction of a
  /// kilocalorie. [shown] is then the amount over; it can be 0.
  final bool isOver;

  const CalorieCardFigures({
    required this.supplied,
    required this.burned,
    required this.goal,
    required this.shown,
    required this.isOver,
  });

  /// [daily], [supplied], [burned], and [left] must already be in the unit
  /// the card is printing (kilocalories, or kilojoules after conversion).
  /// [left] defaults to `daily - supplied`, which is how Home derives it.
  factory CalorieCardFigures.fromTotals({
    required double daily,
    required double supplied,
    required double burned,
    double? left,
  }) {
    final kcalLeft = left ?? (daily - supplied);
    // Same branches as DashboardWidget: cap a negative intake at the goal,
    // and print the overrun as a positive "too much" figure.
    final double ringValue;
    if (kcalLeft > daily) {
      ringValue = daily;
    } else if (kcalLeft < 0) {
      ringValue = kcalLeft.abs();
    } else {
      ringValue = kcalLeft;
    }
    return CalorieCardFigures(
      supplied: supplied.toInt(),
      burned: burned.toInt(),
      goal: daily.toInt(),
      shown: ringValue.toInt(),
      isOver: kcalLeft < 0,
    );
  }
}
