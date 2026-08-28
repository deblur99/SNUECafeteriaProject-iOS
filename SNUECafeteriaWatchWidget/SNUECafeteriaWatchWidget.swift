//
//  SNUECafeteriaWatchWidget.swift
//  SNUECafeteriaWatchWidgetExtension
//

import SwiftUI
import WidgetKit

private enum WatchWidgetDeepLink {
    static let today = URL(string: "snuecafeteria-watch://today")!
}

struct WatchMealWidgetEntry: TimelineEntry {
    let date: Date
    let todayMeal: CachedDayMeal?
    var isPlaceholder = false

    var mealType: MealType {
        MealSchedule.displayMealType(at: date)
    }

    var badgeLabel: String { "오늘 \(mealType.label)" }

    var items: [CachedMenuItem] {
        guard let meal = todayMeal, !meal.isHoliday else { return [] }
        return mealType == .lunch ? meal.sortedLunchItems : meal.sortedDinnerItems
    }

    var isHoliday: Bool { todayMeal?.isHoliday ?? false }

    var menuSummary: String {
        if isHoliday { return "휴무일" }
        let names = items.map(\.name)
        guard !names.isEmpty else { return "식단 없음" }
        return names.prefix(3).joined(separator: " · ")
    }
}

struct WatchMealWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchMealWidgetEntry {
        let samples = CachedDayMeal.sample()
        return WatchMealWidgetEntry(date: Date(), todayMeal: samples.first)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchMealWidgetEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchMealWidgetEntry>) -> Void) {
        let currentDate = Date()
        let calendar = Calendar.kst
        let meals = AppGroupMealCache.load()

        guard !meals.isEmpty else {
            let samples = CachedDayMeal.sample()
            let entry = WatchMealWidgetEntry(
                date: currentDate,
                todayMeal: samples.first,
                isPlaceholder: true
            )
            let retry = calendar.date(byAdding: .minute, value: 15, to: currentDate)!
            completion(Timeline(entries: [entry], policy: .after(retry)))
            return
        }

        let todayMeal = meals.first { calendar.isDateInToday($0.date) }
        let entries = (0 ..< 24).map { offset -> WatchMealWidgetEntry in
            let entryDate = calendar.date(byAdding: .hour, value: offset, to: currentDate)!
            return WatchMealWidgetEntry(date: entryDate, todayMeal: todayMeal)
        }
        let nextRefresh = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    private func makeEntry(at date: Date) -> WatchMealWidgetEntry {
        let meals = AppGroupMealCache.load()
        let todayMeal = meals.first { Calendar.kst.isDateInToday($0.date) }
        return WatchMealWidgetEntry(date: date, todayMeal: todayMeal, isPlaceholder: meals.isEmpty)
    }
}

struct SNUECafeteriaWatchWidgetEntryView: View {
    var entry: WatchMealWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(entry.badgeLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(entry.mealType.color)
                Spacer(minLength: 0)
                if let meal = entry.todayMeal {
                    Text(DateFormatter.kstCompact.string(from: meal.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(entry.menuSummary)
                .font(.caption2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
        .widgetURL(WatchWidgetDeepLink.today)
    }
}

struct SNUECafeteriaWatchWidget: Widget {
    let kind = "SNUECafeteriaWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchMealWidgetProvider()) { entry in
            SNUECafeteriaWatchWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("교대학식")
        .description("오늘의 중식·석식 메뉴")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    SNUECafeteriaWatchWidget()
} timeline: {
    WatchMealWidgetEntry(date: .now, todayMeal: CachedDayMeal.sample().first)
}
