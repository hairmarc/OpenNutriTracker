import SwiftUI
import WidgetKit

/// Reads the App Group snapshot written by `CalorieWidgetSnapshot`.
/// The day boundary matches `DayBoundaryCalc`: subtract the offset, then
/// take the local calendar day. When that day id no longer matches, the
/// widget shows a placeholder instead of yesterday's intake.
private enum CalorieWidgetKeys {
    static let appGroupId = "group.com.megdigital.GOCalorie"
    static let hasData = "ont_calorie_has_data"
    static let day = "ont_calorie_day"
    static let offset = "ont_calorie_offset_minutes"
    static let consumed = "ont_calorie_consumed"
    static let burned = "ont_calorie_burned"
    static let goal = "ont_calorie_goal"
}

private struct CalorieReading {
    var hasData: Bool
    var dayId: String
    var offsetMinutes: Int
    var consumed: Int
    var burned: Int
    var goal: Int

    static func load() -> CalorieReading {
        let defaults = UserDefaults(suiteName: CalorieWidgetKeys.appGroupId)
        return CalorieReading(
            hasData: defaults?.string(forKey: CalorieWidgetKeys.hasData) == "1",
            dayId: defaults?.string(forKey: CalorieWidgetKeys.day) ?? "",
            offsetMinutes: Int(defaults?.string(forKey: CalorieWidgetKeys.offset) ?? "") ?? 0,
            consumed: Int(defaults?.string(forKey: CalorieWidgetKeys.consumed) ?? "") ?? 0,
            burned: Int(defaults?.string(forKey: CalorieWidgetKeys.burned) ?? "") ?? 0,
            goal: Int(defaults?.string(forKey: CalorieWidgetKeys.goal) ?? "") ?? 0
        )
    }

    func isCurrent(at moment: Date) -> Bool {
        guard hasData, goal > 0, !dayId.isEmpty else { return false }
        return dayId == Self.dayId(for: moment, offsetMinutes: offsetMinutes)
    }

    func nextBoundary(after moment: Date) -> Date {
        let offset = Self.sanitisedOffset(offsetMinutes)
        let start = Self.logicalDayStart(for: moment, offsetMinutes: offset)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? moment
        return nextDay.addingTimeInterval(TimeInterval(offset * 60))
    }

    private static func sanitisedOffset(_ minutes: Int) -> Int {
        if minutes < 0 || minutes >= 24 * 60 { return 0 }
        return minutes
    }

    private static func logicalDayStart(for moment: Date, offsetMinutes: Int) -> Date {
        let offset = sanitisedOffset(offsetMinutes)
        let shifted = moment.addingTimeInterval(TimeInterval(-offset * 60))
        return Calendar.current.startOfDay(for: shifted)
    }

    private static func dayId(for moment: Date, offsetMinutes: Int) -> String {
        let start = logicalDayStart(for: moment, offsetMinutes: offsetMinutes)
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}

private struct CalorieEntry: TimelineEntry {
    var date: Date
    var reading: CalorieReading
    var showsNumbers: Bool
}

private struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(
            date: Date(),
            reading: CalorieReading(hasData: false, dayId: "", offsetMinutes: 0, consumed: 0, burned: 0, goal: 0),
            showsNumbers: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        let reading = CalorieReading.load()
        let now = Date()
        completion(
            CalorieEntry(
                date: now,
                reading: reading,
                showsNumbers: reading.isCurrent(at: now)
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let reading = CalorieReading.load()
        let now = Date()
        let boundary = reading.nextBoundary(after: now)
        let current = CalorieEntry(
            date: now,
            reading: reading,
            showsNumbers: reading.isCurrent(at: now)
        )
        let expired = CalorieEntry(
            date: boundary,
            reading: reading,
            showsNumbers: false
        )
        completion(Timeline(entries: [current, expired], policy: .after(boundary)))
    }
}

/// Same roles as `AppPalette`: accent ring, error when the day is over
/// the goal, amber for the activity slice, teal for food eaten.
private struct CaloriePalette {
    var isDark: Bool

    var track: Color {
        isDark ? Color(red: 0x3A / 255, green: 0x3A / 255, blue: 0x3C / 255)
            : Color(red: 0xE3 / 255, green: 0xE3 / 255, blue: 0xE8 / 255)
    }

    var accent: Color {
        isDark ? Color(red: 0x34 / 255, green: 0xD0 / 255, blue: 0x8A / 255)
            : Color(red: 0x0E / 255, green: 0x7A / 255, blue: 0x4D / 255)
    }

    var over: Color {
        isDark ? Color(red: 1, green: 0xB4 / 255, blue: 0xAB / 255)
            : Color(red: 0xC4 / 255, green: 0x45 / 255, blue: 0x3A / 255)
    }

    var activity: Color {
        isDark ? Color(red: 0xF2 / 255, green: 0xB4 / 255, blue: 0x5A / 255)
            : Color(red: 0xB8 / 255, green: 0x74 / 255, blue: 0x10 / 255)
    }

    var food: Color {
        isDark ? Color(red: 0x49 / 255, green: 0xC9 / 255, blue: 0xB8 / 255)
            : Color(red: 0x1F / 255, green: 0x8E / 255, blue: 0x80 / 255)
    }

    var text: Color {
        isDark ? Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255)
            : Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    }

    var muted: Color {
        isDark ? Color(red: 0xAE / 255, green: 0xAE / 255, blue: 0xB2 / 255)
            : Color(red: 0x6E / 255, green: 0x6E / 255, blue: 0x73 / 255)
    }

    /// White card in light mode, matching the in-app calorie card.
    var canvas: Color {
        isDark ? Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
            : Color.white
    }
}

private struct CalorieWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    var entry: CalorieEntry

    private var palette: CaloriePalette {
        CaloriePalette(isDark: colorScheme == .dark)
    }

    var body: some View {
        Group {
            if entry.showsNumbers {
                progressBody
            } else {
                placeholderBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(palette.canvas)
    }

    private var progressBody: some View {
        let eaten = max(entry.reading.consumed, 0)
        let burned = max(entry.reading.burned, 0)
        let remaining = entry.reading.goal - entry.reading.consumed
        let isOver = remaining < 0
        let shown = isOver ? -remaining : remaining
        return VStack(spacing: 1) {
            ZStack {
                ring
                VStack(spacing: 0) {
                    Text("\(shown)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(isOver ? palette.over : palette.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if isOver {
                        Text("kcal too much")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.over)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                calorieStat(
                    symbol: "fork.knife",
                    value: "\(eaten)",
                    tint: palette.food
                )
                Spacer(minLength: 4)
                calorieStat(
                    symbol: "flame.fill",
                    value: burned > 0 ? "−\(burned)" : "0",
                    tint: burned > 0 ? palette.activity : palette.muted
                )
            }
        }
        .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(isOver: isOver, shown: shown, eaten: eaten, burned: burned))
    }

    private var ring: some View {
        let goal = max(entry.reading.goal, 1)
        let eaten = max(entry.reading.consumed, 0)
        let burned = max(entry.reading.burned, 0)
        let remaining = entry.reading.goal - entry.reading.consumed
        let isOver = remaining < 0
        let consumedFraction = min(max(Double(eaten) / Double(goal), 0), 1)
        let burnedFraction = min(max(Double(burned) / Double(goal), 0), consumedFraction)
        return ZStack {
            Circle()
                .stroke(palette.track, lineWidth: 13)
            Circle()
                .trim(from: 0, to: consumedFraction)
                .stroke(
                    isOver ? palette.over : palette.accent,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if burnedFraction > 0 {
                Circle()
                    .trim(from: consumedFraction - burnedFraction, to: consumedFraction)
                    .stroke(
                        palette.activity,
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func calorieStat(symbol: String, value: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func accessibilityText(isOver: Bool, shown: Int, eaten: Int, burned: Int) -> String {
        let state = isOver
            ? "\(shown) kilocalories over the goal"
            : "\(shown) kilocalories left"
        return "\(state), \(eaten) eaten, \(burned) reduced by activity"
    }

    private var placeholderBody: some View {
        VStack(spacing: 4) {
            Text("Calories")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(palette.text)
                .lineLimit(1)
            Text("Open the app")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
        }
        .padding(12)
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}

struct CalorieProgressWidget: Widget {
    let kind = "CalorieProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieWidgetView(entry: entry)
        }
        .configurationDisplayName("GO Calorie")
        .description("Calories left today, and how food and activity change them.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
    }
}
