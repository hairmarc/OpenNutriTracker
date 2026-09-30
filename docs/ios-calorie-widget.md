# iOS calorie widget

A small, read-only Home Screen widget shows how many calories are left today. The ring matches the home card: green while calories remain, red when the day is over the goal, with an amber slice for calories offset by activity. Food and activity totals sit under the ring. It reads an App Group snapshot written when Home finishes loading. It does not open the encrypted Hive database. Activity kilocalories are stored as `ont_calorie_burned`.

The whole numbers are the same ones the home card prints. Each total is truncated toward zero, and calories left are truncated after intake is subtracted from the goal. Those two integers are `ont_calorie_shown` (the absolute center value) and `ont_calorie_over` (`1` when the day is past the goal, including by a fraction of a kilocalorie).

Android stores the same snapshot and has no widget UI yet. That work is tracked separately.

## App Group

Both the Runner target and the `CalorieWidget` extension use:

`group.com.megdigital.GOCalorie`

The extension bundle ids are:

- full: `com.opennutritracker.ont.opennutritracker.CalorieWidget`
- develop: `com.opennutritracker.ont.opennutritracker.develop.CalorieWidget`

The id must stay a prefix of the parent app id for that flavor. The Dart constant `CalorieWidgetSnapshot.appGroupId` and `CalorieWidgetKeys.appGroupId` in `ios/CalorieWidget/CalorieWidget.swift` must stay the same string.

## Local development

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the Runner target, then Signing & Capabilities. Confirm the App Groups capability lists the group above. Repeat for the CalorieWidget target.
3. For a simulator build, the entitlement file in the project is enough. Sign with your Apple team if Xcode asks. The project file records the maintainer team used for release; a local debug build can use another team as long as both targets share it.
4. Run the app once so Home writes today's numbers, then add the Calories widget from the Home Screen.

The widget shows "Open the app" until that first write, and again after the configured day boundary, until the app writes the new day.

## Release signing

App Store and TestFlight archives need the group and both extension bundle ids registered on the Apple Developer team that signs OpenNutriTracker (`DEVELOPMENT_TEAM` `79AJPC6DP3`).

1. In Certificates, Identifiers & Profiles, create the App Group `group.com.megdigital.GOCalorie` if it is not already there.
2. Enable that App Group on the existing app ids (`com.opennutritracker.ont.opennutritracker` and the develop id).
3. Register the two extension bundle ids and enable the same App Group on each.
4. Regenerate the signing profiles (the project uses fastlane match for Release and Profile) so the new ids and the group are included. Debug stays on automatic signing.
5. Archive from the `full` scheme. The extension is embedded by the Runner target.

`flutter build ios --no-codesign` does not need those profiles. A signed archive does.
