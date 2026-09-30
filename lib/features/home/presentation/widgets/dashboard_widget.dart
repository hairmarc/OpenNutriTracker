import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/sf_symbol_icon.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/calorie_card_figures.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class DashboardWidget extends StatefulWidget {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const DashboardWidget({
    super.key,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  void _openKcalGoalInfoScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const KcalGoalInfoScreen()));
  }

  @override
  Widget build(BuildContext context) {
    double gaugeValue = 0;
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    double displayed(double kcal) =>
        usesKilojoules ? UnitCalc.kcalToKj(kcal) : kcal;
    // Same integers the home-screen widget publishes.
    final figures = CalorieCardFigures.fromTotals(
      daily: displayed(widget.totalKcalDaily),
      supplied: displayed(widget.totalKcalSupplied),
      burned: displayed(widget.totalKcalBurned),
      left: displayed(widget.totalKcalLeft),
    );
    String kcalLabelText = usesKilojoules
        ? '${S.of(context).kjLabel} ${S.of(context).energyLeftLabel}'
        : S.of(context).kcalLeftLabel;

    if (widget.totalKcalLeft > widget.totalKcalDaily) {
      gaugeValue = 0;
    } else if (widget.totalKcalLeft < 0) {
      gaugeValue = 1;
      kcalLabelText = usesKilojoules
          ? '${S.of(context).kjLabel} ${S.of(context).energyTooMuchLabel}'
          : S.of(context).kcalTooMuchLabel;
    } else {
      gaugeValue =
          (widget.totalKcalDaily - widget.totalKcalLeft) /
          widget.totalKcalDaily;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final isOver = widget.totalKcalLeft < 0;
    final overColor = Theme.of(context).colorScheme.error;
    // Eaten arc, then the activity slice painted over its leading edge.
    // Activity is already inside the daily goal, so this slice is the
    // part of today's food that exercise offset. Past the goal the whole
    // ring switches to the error color; the slice stays on top of it.
    final consumedFraction = gaugeValue.clamp(0.0, 1.0);
    final burnedFraction = widget.totalKcalDaily <= 0
        ? 0.0
        : (widget.totalKcalBurned / widget.totalKcalDaily).clamp(
            0.0,
            consumedFraction,
          );
    final burnedInt = figures.burned;
    final gaugeLabel = burnedInt > 0
        ? '${figures.shown} $kcalLabelText, '
              '$burnedInt ${S.of(context).burnedLabel}'
        : '${figures.shown} $kcalLabelText';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing4,
      ),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(
              Dimens.spacing24,
              Dimens.spacing20,
              Dimens.spacing24,
              Dimens.spacing24,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Two equal halves; each stat pins itself to its card
                    // edge via its own cross-axis alignment. A Spacer next
                    // to loose-fit Flexible children would leave the spare
                    // width at the row end and pull the activity total off
                    // the edge. The words stay in the spoken label only.
                    Expanded(
                      child: _MiniStat(
                        icon: SfSymbolIcon(
                          symbol: 'fork.knife',
                          size: 20,
                          color: palette.proteinColor,
                          fallback: Icon(
                            Icons.flatware_rounded,
                            color: palette.proteinColor,
                            size: 20,
                          ),
                        ),
                        value: '${figures.supplied}',
                        spokenLabel: S.of(context).suppliedLabel,
                        color: palette.proteinColor,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        icon: Icon(
                          Icons.local_fire_department_rounded,
                          color: palette.carbsColor,
                          size: 20,
                        ),
                        value: burnedInt > 0 ? '−$burnedInt' : '$burnedInt',
                        spokenLabel: S.of(context).burnedLabel,
                        color: palette.carbsColor,
                        valueColor: burnedInt > 0 ? palette.carbsColor : null,
                        trailing: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing8),
                Semantics(
                  identifier: 'home-kcal-gauge',
                  label: gaugeLabel,
                  hint: S.of(context).settingsKcalGoalInfoLabel,
                  button: true,
                  excludeSemantics: true,
                  // excludeSemantics strips the GestureDetector's semantic
                  // tap action along with the rest of the subtree, so the
                  // node needs its own onTap for screen readers to be able
                  // to activate the button it announces.
                  onTap: _openKcalGoalInfoScreen,
                  // Tapping the gauge opens the calorie-goal transparency
                  // screen, so the central number on the dashboard is one
                  // tap away from its full derivation.
                  child: Tooltip(
                    message: S.of(context).settingsKcalGoalInfoLabel,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openKcalGoalInfoScreen,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Fill the card, up to a cap so a wide window does
                          // not grow a poster-sized ring. The stroke scales
                          // with the old 16-on-180 proportion.
                          final available = constraints.maxWidth;
                          final diameter = available > 320 ? 320.0 : available;
                          final lineWidth = (diameter * 16 / 180).clamp(
                            16.0,
                            28.0,
                          );
                          return _CalorieRing(
                            diameter: diameter,
                            lineWidth: lineWidth,
                            consumedFraction: consumedFraction,
                            burnedFraction: burnedFraction,
                            progressColor: isOver
                                ? overColor
                                : Theme.of(context).colorScheme.primary,
                            trackColor: palette.surfaceMuted,
                            activityColor: palette.carbsColor,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedFlipCounter(
                                  duration: const Duration(milliseconds: 800),
                                  curve: AppMotion.emphasized,
                                  value: figures.shown,
                                  textStyle: textTheme.displaySmall?.copyWith(
                                    height: 1,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    color: isOver ? overColor : null,
                                  ),
                                ),
                                if (isOver) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    kcalLabelText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleSmall?.copyWith(
                                      color: overColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Row(
            children: [
              Expanded(
                child: _MacroTile(
                  label: S.of(context).carbsLabel,
                  intake: widget.totalCarbsIntake,
                  goal: widget.totalCarbsGoal,
                  color: palette.carbs,
                  palette: palette,
                ),
              ),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: _MacroTile(
                  label: S.of(context).fatLabel,
                  intake: widget.totalFatsIntake,
                  goal: widget.totalFatsGoal,
                  color: palette.fat,
                  palette: palette,
                ),
              ),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: _MacroTile(
                  label: S.of(context).proteinLabel,
                  intake: widget.totalProteinsIntake,
                  goal: widget.totalProteinsGoal,
                  color: palette.protein,
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final double diameter;
  final double lineWidth;
  final double consumedFraction;
  final double burnedFraction;
  final Color progressColor;
  final Color trackColor;
  final Color activityColor;
  final Widget center;

  const _CalorieRing({
    required this.diameter,
    required this.lineWidth,
    required this.consumedFraction,
    required this.burnedFraction,
    required this.progressColor,
    required this.trackColor,
    required this.activityColor,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    final radius = diameter / 2;
    return Align(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularPercentIndicator(
              radius: radius,
              lineWidth: lineWidth,
              percent: consumedFraction,
              animation: true,
              // The dashboard's first-ever build of a session (a cold
              // start, or landing on Home right after seeding/onboarding)
              // must show the real value immediately — animating up from
              // 0% every time reads as the data being wrong for a beat,
              // not as a nice reveal. Later rebuilds (e.g. logging a meal)
              // still animate from the old percent, since that's a real,
              // visible change worth animating.
              animateToInitialPercent: false,
              animationDuration: 800,
              curve: AppMotion.emphasized,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: trackColor,
              progressColor: progressColor,
              center: center,
            ),
            if (burnedFraction > 0)
              IgnorePointer(
                child: CircularPercentIndicator(
                  radius: radius,
                  lineWidth: lineWidth,
                  percent: burnedFraction,
                  startAngle: (consumedFraction - burnedFraction) * 360,
                  animation: false,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.transparent,
                  progressColor: activityColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final Widget icon;
  final String value;
  final String spokenLabel;
  final Color color;
  final Color? valueColor;
  final bool trailing;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.spokenLabel,
    required this.color,
    this.valueColor,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final number = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.titleLarge?.copyWith(
        color: valueColor,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    );
    final badge = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: icon,
    );
    return Semantics(
      label: '$value $spokenLabel',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: trailing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: trailing
            ? [Flexible(child: number), const SizedBox(width: 6), badge]
            : [badge, const SizedBox(width: 6), Flexible(child: number)],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double intake;
  final double goal;
  final Color color;
  final AppPalette palette;

  const _MacroTile({
    required this.label,
    required this.intake,
    required this.goal,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pct = (goal <= 0) ? 0.0 : (intake / goal).clamp(0.0, 1.0);
    return AppCard(
      borderRadius: Dimens.radiusL,
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing16,
        Dimens.spacing16,
        Dimens.spacing16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: palette.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Text(
            '${intake.toInt()}/${goal.toInt()} g',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: palette.textStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
