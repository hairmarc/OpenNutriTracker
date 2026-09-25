import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';

class _FakeBreakdownUsecase extends Fake
    implements GetKcalGoalBreakdownUsecase {
  final KcalGoalBreakdownEntity breakdown;

  _FakeBreakdownUsecase(this.breakdown);

  @override
  Future<KcalGoalBreakdownEntity> getBreakdown() async => breakdown;
}

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => EnergyUnitProvider(usesKilojoules: false),
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUp(() {
    // The gauge navigates to KcalGoalInfoScreen, which pulls its usecase
    // from the locator when none is injected.
    locator.registerSingleton<GetKcalGoalBreakdownUsecase>(
      _FakeBreakdownUsecase(
        KcalGoalBreakdownEntity.compute(
          user: UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
          totalKcalActivities: 0,
        ),
      ),
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'kcal gauge exposes a semantic tap action that opens the goal screen '
    '(regression: excludeSemantics stripped the GestureDetector tap, so '
    'screen readers announced a button that could not be activated)',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          const DashboardWidget(
            totalKcalSupplied: 800,
            totalKcalBurned: 200,
            totalKcalDaily: 2500,
            totalKcalLeft: 1900,
            totalCarbsIntake: 100,
            totalFatsIntake: 30,
            totalProteinsIntake: 60,
            totalCarbsGoal: 375,
            totalFatsGoal: 69,
            totalProteinsGoal: 93,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gaugeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.identifier == 'home-kcal-gauge',
      );
      expect(gaugeFinder, findsOneWidget);

      final node = tester.getSemantics(gaugeFinder);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason:
            'excludeSemantics drops the GestureDetector\'s tap action, '
            'so the Semantics node must register its own onTap',
      );

      // Activate the node the way TalkBack/VoiceOver do — via the semantic
      // action, not a pointer tap.
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(find.byType(KcalGoalInfoScreen), findsOneWidget);

      semanticsHandle.dispose();
    },
  );

  testWidgets('over the goal turns the ring red and activity is a reduction', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        const DashboardWidget(
          totalKcalSupplied: 2300,
          totalKcalBurned: 200,
          totalKcalDaily: 2000,
          totalKcalLeft: -300,
          totalCarbsIntake: 100,
          totalFatsIntake: 30,
          totalProteinsIntake: 60,
          totalCarbsGoal: 300,
          totalFatsGoal: 55,
          totalProteinsGoal: 75,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('kcal too much'), findsOneWidget);
    expect(find.text('−200'), findsOneWidget);

    final context = tester.element(find.byType(DashboardWidget));
    final rings = tester
        .widgetList<CircularPercentIndicator>(
          find.byType(CircularPercentIndicator),
        )
        .toList();
    expect(rings, hasLength(2));
    expect(rings.first.percent, 1);
    expect(rings.first.progressColor, Theme.of(context).colorScheme.error);
    expect(rings.last.progressColor, const Color(0xFFB87410));
    expect(rings.last.percent, closeTo(200 / 2000, 0.0001));
  });

  testWidgets('activity paints an amber slice on the eaten arc', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        const DashboardWidget(
          totalKcalSupplied: 800,
          totalKcalBurned: 200,
          totalKcalDaily: 2500,
          totalKcalLeft: 1700,
          totalCarbsIntake: 100,
          totalFatsIntake: 30,
          totalProteinsIntake: 60,
          totalCarbsGoal: 375,
          totalFatsGoal: 69,
          totalProteinsGoal: 93,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('kcal left'), findsNothing);
    expect(find.text('−200'), findsOneWidget);

    final context = tester.element(find.byType(DashboardWidget));
    final rings = tester
        .widgetList<CircularPercentIndicator>(
          find.byType(CircularPercentIndicator),
        )
        .toList();
    expect(rings.first.progressColor, Theme.of(context).colorScheme.primary);
    expect(rings.last.progressColor, const Color(0xFFB87410));
    expect(rings.last.startAngle, closeTo((800 - 200) / 2500 * 360, 0.001));
  });
}
