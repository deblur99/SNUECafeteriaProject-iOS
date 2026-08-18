//
//  SNUECafeteriaWidget.swift
//  SNUECafeteriaWidget
//
//  Created by 한현민 on 5/18/26.
//

import SwiftUI
import WidgetKit
import SNUECafeteriaShared

// MARK: - Deep Link URLs

private enum WidgetDeepLink {
    /// 앱의 "오늘의 식단" 페이지 (오늘 탭 + 오늘 세그먼트)
    static let today = URL(string: "snuecafeteria://today")!
    /// 앱의 "내일의 식단" 페이지 (오늘 탭 + 내일 세그먼트)
    static let tomorrow = URL(string: "snuecafeteria://tomorrow")!
}

// MARK: - Timeline Entry

struct MealEntry: TimelineEntry {
    let date: Date
    let todayMeal: CachedDayMeal?
    let tomorrowMeal: CachedDayMeal?
    /// true면 캐시 없음 — 실제 데이터 대신 샘플로 렌더링하고 .redacted 스켈레톤 표시
    var isPlaceholder: Bool = false

    /// 현재 시간 기준으로 가장 가까운 식사 유형 (14시 이전은 중식, 이후는 석식)
    var mealType: MealType {
        Calendar.kst.component(.hour, from: date) < 14 ? .lunch : .dinner
    }

    /// Small 위젯 배지용 레이블 ("오늘 중식" / "오늘 석식")
    var smallBadgeLabel: String { "오늘 교대 \(mealType.label)" }

    /// Small 위젯에 표시할 메뉴 목록
    var items: [CachedMenuItem] {
        guard let meal = todayMeal, !meal.isHoliday else { return [] }
        return mealType == .lunch ? meal.sortedLunchItems : meal.sortedDinnerItems
    }

    /// 오늘이 휴무일인지 여부
    var isHoliday: Bool { todayMeal?.isHoliday ?? false }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MealEntry {
        let samples = CachedDayMeal.sample()
        return MealEntry(date: Date(), todayMeal: samples.first, tomorrowMeal: samples.last)
    }

    func getSnapshot(in context: Context, completion: @escaping (MealEntry) -> ()) {
        let samples = CachedDayMeal.sample()
        completion(MealEntry(date: Date(), todayMeal: samples.first, tomorrowMeal: samples.last))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealEntry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.kst

        guard let meals = loadCachedMeals() else {
            // 앱이 아직 실행되지 않아 캐시 없음: 샘플 데이터 + isPlaceholder로 스켈레톤 표시
            // 앱 실행 후 reloadAllTimelines()가 호출되면 실제 데이터로 즉시 갱신됨
            let samples = CachedDayMeal.sample()
            let entry = MealEntry(
                date: currentDate,
                todayMeal: samples.first,
                tomorrowMeal: samples.last,
                isPlaceholder: true
            )
            let retry = calendar.date(byAdding: .minute, value: 15, to: currentDate)!
            completion(Timeline(entries: [entry], policy: .after(retry)))
            return
        }

        // toCachedModel()에서 KST 자정으로 정규화된 날짜이므로 isDateInToday/isDate(inSameDayAs:) 비교 가능
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let todayMeal = meals.first { calendar.isDateInToday($0.date) }
        let tomorrowMeal = meals.first { calendar.isDate($0.date, inSameDayAs: tomorrowDate) }
        print("📅 [Widget] 오늘: \(todayMeal == nil ? "없음" : "있음"), 내일: \(tomorrowMeal == nil ? "없음" : "있음")")

        let entries = (0 ..< 24).map { offset -> MealEntry in
            let entryDate = calendar.date(byAdding: .hour, value: offset, to: currentDate)!
            return MealEntry(date: entryDate, todayMeal: todayMeal, tomorrowMeal: tomorrowMeal)
        }

        let nextRefresh = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    /// App Groups의 UserDefaults에서 캐시된 식단 데이터를 불러온다. 앱이 아직 실행되지 않아 데이터가 없거나, 디코딩에 실패하면 nil을 반환한다.
    private func loadCachedMeals() -> [CachedDayMeal]? {
        let meals = AppGroupMealCache.load()
        guard !meals.isEmpty else {
            print("⚠️ [Widget] App Groups 캐시 없음 — 앱이 아직 한 번도 실행되지 않은 것으로 추정")
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.kst.timeZone
        let dates = meals.map { formatter.string(from: $0.date) }.joined(separator: ", ")
        print("✅ [Widget] 캐시 로드 성공: \(meals.count)개 [\(dates)]")
        return meals
    }
}

// MARK: - Design System

/// 위젯 크기별 레이아웃·타이포그래피 디자인 토큰
enum WidgetSizeMetrics {
    case small, medium, large

    /// 뷰 바깥쪽 패딩 (containerBackground 기준)
    var outerPadding: CGFloat {
        switch self {
        case .small: 12
        case .medium: 0
        case .large: 0
        }
    }

    /// 메뉴 항목 텍스트 크기
    var itemFontSize: CGFloat {
        switch self {
        case .small: 12
        case .medium: 12
        case .large: 11
        }
    }

    /// 카드당 최대 표시 항목 수
    var maxItems: Int {
        switch self {
        case .small: 4
        case .medium: 5
        case .large: 6
        }
    }

    /// MealTypeCircle 지름 (Small에서는 사용 안 함)
    var circleSize: CGFloat {
        switch self {
        case .small: 0
        case .medium: 32
        case .large: 32
        }
    }
}

// MARK: - Subviews

/// Small 전용: Capsule 형태로 "오늘 중식" / "오늘 석식" 표시
private struct SmallMealBadge: View {
    let entry: MealEntry
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var backgroundFill: Color {
        switch renderingMode {
        case .fullColor: entry.mealType.color
        case .vibrant: Color.primary.opacity(0.54) // Standby 야간: 검정 배경에서 보이도록 높임
        default: Color.primary.opacity(0.12) // accented (틴트)
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "fork.knife")
            Text(entry.smallBadgeLabel)
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(renderingMode == .fullColor ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(backgroundFill))
    }
}

/// Medium / Large 카드 전용: Circle 형태로 "중식" / "석식" 표시
private struct MealTypeCircle: View {
    let mealType: MealType
    let size: CGFloat
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var backgroundFill: Color {
        switch renderingMode {
        case .fullColor: mealType.color
        case .vibrant: Color.primary.opacity(0.28)
        default: Color.primary.opacity(0.12)
        }
    }

    var body: some View {
        Text(mealType.label)
            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
            .foregroundStyle(renderingMode == .fullColor ? .white : .primary)
            .frame(width: size, height: size)
            .background(Circle().fill(backgroundFill))
    }
}

/// 휴무일 / 식단 없음 / 메뉴 목록을 상황에 맞게 표시하는 공통 컴포넌트
private struct MealContentView: View {
    let isHoliday: Bool
    let items: [CachedMenuItem]
    let metrics: WidgetSizeMetrics
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if isHoliday || items.isEmpty {
            let text = isHoliday ? "휴무일" : "식단 없음"
            
            Text(text)
                .font(.system(size: metrics.itemFontSize))
                .foregroundStyle(
                    renderingMode != .vibrant ? .secondary : .primary
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            MealItemList(items: items, metrics: metrics)
        }
    }
}

/// 메뉴 항목 리스트 + "외 N개" 표시를 담당하는 컴포넌트 (Medium / Large 카드 내부에서 사용) - Small에서는 최대 4개까지 다 보여주므로 필요 없음
private struct MealItemList: View {
    let items: [CachedMenuItem]
    let metrics: WidgetSizeMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(items.prefix(metrics.maxItems), id: \.name) { item in
                Text(item.name)
                    .font(.system(size: metrics.itemFontSize))
                    .lineLimit(1)
            }
            
            if items.count > metrics.maxItems {
                Text("외 \(items.count - metrics.maxItems)개")
                    .font(.system(size: metrics.itemFontSize - 1))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Medium / Large 공용: Circle 배지 + 메뉴 목록 카드
private struct WidgetMealCard: View {
    let mealType: MealType
    let meal: CachedDayMeal?
    let metrics: WidgetSizeMetrics

    private var isHoliday: Bool { meal?.isHoliday ?? false }
    private var items: [CachedMenuItem] {
        guard let meal, !meal.isHoliday else { return [] }
        return mealType == .lunch ? meal.sortedLunchItems : meal.sortedDinnerItems
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            MealTypeCircle(mealType: mealType, size: metrics.circleSize)
                .frame(width: metrics.circleSize + 12)
                .padding(.vertical, 10)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)

            MealContentView(isHoliday: isHoliday, items: items, metrics: metrics)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Large 전용: 날짜 헤더 + 중식·석식 카드 한 쌍
private struct WidgetDaySection: View {
    let label: String
    let meal: CachedDayMeal?
    let metrics: WidgetSizeMetrics
    var isToday: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: isToday ? "fork.knife" : "calendar")
                Text(label)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)

            if let meal {
                HStack(spacing: 8) {
                    WidgetMealCard(mealType: .lunch, meal: meal, metrics: metrics)
                    WidgetMealCard(mealType: .dinner, meal: meal, metrics: metrics)
                }
                .frame(maxHeight: .infinity)
            } else {
                Text("데이터 없음")
                    .font(.system(size: metrics.itemFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Size-specific Entry Views

/// Small: Capsule 배지 + 오늘 기준 가장 가까운 중식 or 석식 메뉴
private struct SmallEntryView: View {
    let entry: MealEntry
    private let metrics = WidgetSizeMetrics.small

    var body: some View {
        VStack(spacing: 8) {
            SmallMealBadge(entry: entry)

            MealContentView(isHoliday: entry.isHoliday, items: entry.items, metrics: metrics)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.vertical, metrics.outerPadding)
        .widgetURL(WidgetDeepLink.today)
    }
}

/// Medium: 오늘 중식·석식 나란히 표시
private struct MediumEntryView: View {
    let entry: MealEntry
    private let metrics = WidgetSizeMetrics.medium

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "fork.knife")
                Text("오늘 교대 메뉴")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                WidgetMealCard(mealType: .lunch, meal: entry.todayMeal, metrics: metrics)
                WidgetMealCard(mealType: .dinner, meal: entry.todayMeal, metrics: metrics)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(metrics.outerPadding)
        .widgetURL(WidgetDeepLink.today)
    }
}

/// Large: 오늘 + 내일 메뉴 (각 섹션을 Link로 감싸 서로 다른 탭으로 분기)
private struct LargeEntryView: View {
    let entry: MealEntry
    private let metrics = WidgetSizeMetrics.large

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Link(destination: WidgetDeepLink.today) {
                WidgetDaySection(label: "오늘 교대 메뉴", meal: entry.todayMeal, metrics: metrics)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)

            Link(destination: WidgetDeepLink.tomorrow) {
                WidgetDaySection(label: "내일 교대 메뉴", meal: entry.tomorrowMeal, metrics: metrics, isToday: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(metrics.outerPadding)
    }
}

// MARK: - Entry View

struct SNUECafeteriaWidgetEntryView: View {
    var entry: Provider.Entry // 컴파일 타임에 MealEntry로 자동 추론됨
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallEntryView(entry: entry)
            case .systemMedium:
                MediumEntryView(entry: entry)
            case .systemLarge:
                LargeEntryView(entry: entry)
            default:
                SmallEntryView(entry: entry)
            }
        }
        // isPlaceholder일 때 전체 뷰를 스켈레톤으로 표시 (샘플 데이터 위에 redacted 마스크)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Widgets

struct SNUECafeteriaSmallWidget: Widget {
    // 특정 위젯을 식별하기 위한 고유 식별자
    let kind: String = "SNUECafeteriaWidget.small"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SNUECafeteriaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 서울교대 학식")
        .description("오늘의 가장 가까운 학식 메뉴를 확인합니다.")
        .supportedFamilies([.systemSmall])
    }
}

struct SNUECafeteriaMediumWidget: Widget {
    // 특정 위젯을 식별하기 위한 고유 식별자
    let kind: String = "SNUECafeteriaWidget.medium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SNUECafeteriaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 서울교대 학식")
        .description("오늘의 학식 메뉴를 확인합니다.")
        .supportedFamilies([.systemMedium])
    }
}

struct SNUECafeteriaLargeWidget: Widget {
    // 특정 위젯을 식별하기 위한 고유 식별자
    let kind: String = "SNUECafeteriaWidget.large"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SNUECafeteriaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 서울교대 학식")
        .description("오늘의 학식 메뉴와 내일의 학식 메뉴를 확인합니다.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SNUECafeteriaSmallWidget()
} timeline: {
    MealEntry(date: .now, todayMeal: CachedDayMeal.sample().first, tomorrowMeal: CachedDayMeal.sample().last, isPlaceholder: true)
    MealEntry(date: .now, todayMeal: CachedDayMeal.sample().first, tomorrowMeal: CachedDayMeal.sample().last)
}

#Preview("Medium", as: .systemMedium) {
    SNUECafeteriaMediumWidget()
} timeline: {
    MealEntry(date: .now, todayMeal: CachedDayMeal.sample().first, tomorrowMeal: CachedDayMeal.sample().last)
}

#Preview("Large", as: .systemLarge) {
    SNUECafeteriaLargeWidget()
} timeline: {
    MealEntry(date: .now, todayMeal: CachedDayMeal.sample().first, tomorrowMeal: CachedDayMeal.sample().last)
}
