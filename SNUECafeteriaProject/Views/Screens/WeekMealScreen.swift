//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

// MARK: - WeekMealScreen

struct WeekMealScreen: View {
    @Environment(MealStore.self) private var mealStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var isSheetPresented: Bool = false
    /// 주차별 스크롤 위치 (키: 주의 시작일, 값: 뷰포트 상단에 위치한 날짜)
    /// - 사용자 스크롤: LazyVGrid에 scrollTargetLayout()를 달면 partial-visible 카드도 추적
    /// - 시트/툴바 이동: 해당 날짜를 직접 저장 → scrollPosition(id:anchor:)로 이동
    @State private var scrollPositions: [Date: Date] = [:]
    /// 툴바/시트에서 임의 날짜로 이동할 때 설정하는 바인딩 (HorizontalPageSwipeView에서 소비 후 nil로 초기화됨)
    @State private var navigationTarget: Date? = nil

    var body: some View {
        NavigationStack {
            HorizontalPageSwipeView(
                currentItem: $selectedDate,
                prevItem: nearestPrevDate,
                nextItem: nearestNextDate,
                programmaticTarget: $navigationTarget
            ) { date in
                weekPane(for: date)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    WeekSelectorView(
                        selectedDate: Binding(
                            get: { selectedDate },
                            set: { navigationTarget = $0 }
                        ),
                        availableDates: mealStore.availableDates
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("날짜 선택", systemImage: "calendar") {
                        isSheetPresented.toggle()
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                WeekDatePickerModal(
                    initialDate: selectedDate,
                    availableDates: mealStore.availableDates
                ) { date in
                    let newDate = Calendar.kst.startOfDay(for: date)
                    // 목적지 주의 스크롤 위치를 해당 날짜 카드로 미리 지정
                    scrollPositions[weekStart(for: newDate)] = newDate
                    navigationTarget = newDate
                }
            }
        }
    }
}

// MARK: - Navigation

private extension WeekMealScreen {
    /// 현재 주보다 이전 주 중 데이터가 있는 가장 가까운 날짜
    var nearestPrevDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealStore.availableDates.filter { $0 < interval.start }.max()
    }

    /// 현재 주보다 이후 주 중 데이터가 있는 가장 가까운 날짜
    var nearestNextDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealStore.availableDates.filter { $0 >= interval.end }.min()
    }
}

// MARK: - Helpers

private extension WeekMealScreen {
    func weekStart(for date: Date) -> Date {
        Calendar.kstWeekInterval(for: date)?.start ?? date
    }

    func weekDays(for anchorDate: Date) -> [Date] {
        guard let interval = Calendar.kstWeekInterval(for: anchorDate) else { return [] }
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            guard let next = Calendar.kst.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    /// 너비와 size class 기반으로 열 레이아웃을 결정
    /// - iPhone 세로 (< 500pt): 1열
    /// - iPhone 가로 (≥ 500pt): 2열
    /// - iPad 미니 세로 (< 768pt): 1열
    /// - iPad 세로 / iPad 미니 가로 (768pt ~ 1099pt): 2열
    /// - iPad 가로 (≥ 1100pt): 3열
    func gridColumns(for width: CGFloat) -> [GridItem] {
        let count: Int
        if (horizontalSizeClass ?? .compact) == .compact {
            count = width >= 500 ? 2 : 1
        } else {
            count = width >= 1100 ? 3 : (width >= 768 ? 2 : 1)
        }
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
}

// MARK: - Layout

private extension WeekMealScreen {
    /// anchorDate 기준 한 주의 콘텐츠 pane. 주차별 스크롤 위치 자동 기억·복원.
    @ViewBuilder
    func weekPane(for anchorDate: Date) -> some View {
        let weekStartDate = weekStart(for: anchorDate)
        let days = weekDays(for: anchorDate)
        // get: 저장된 날짜 반환. 없으면 첫 날(월요일)로 이동.
        //      nil을 반환하면 ScrollView가 이전 주의 offset을 그대로 유지(scroll bleeding)하므로
        //      미방문 주차도 명시적으로 첫 날을 지정해 최상단을 보장한다.
        // set: center pane(현재 선택된 주차)이고 유효한 날짜인 경우만 저장.
        //      off-screen pane의 SET 이벤트도 차단해 기존 저장 위치 덮어쓰기 방지.
        let positionIDBinding = Binding<Date?>(
            get: { scrollPositions[weekStartDate] ?? days.first },
            set: { newDate in
                guard let d = newDate else { return }
                guard weekStartDate == weekStart(for: selectedDate) else { return }
                scrollPositions[weekStartDate] = d
            }
        )
        
        // MARK: - Week Pane View
        
        if days.isEmpty {
            ContentUnavailableView(
                "식단 정보 없음",
                systemImage: "fork.knife",
                description: Text("해당 주의 식단 정보가 없습니다.")
            )
        } else {
            GeometryReader { geometry in
                let outerColumns = gridColumns(for: geometry.size.width).count
                ScrollView {
                    LazyVGrid(columns: gridColumns(for: geometry.size.width), spacing: 16) {
                        ForEach(days, id: \.self) { date in
                            dayContent(for: date, outerColumns: outerColumns)
                                .id(date)
                        }
                    }
                    .scrollTargetLayout()
                    .padding()
                }
                // positionIDBinding.get이 days.first를 fallback으로 반환하므로
                // .id(weekStartDate)로 강제 재생성 없이도 scroll bleeding이 발생하지 않는다
                
                // (모듈 관련)
                // - .scrollPosition(id:)는 ScrollView 위에 붙는 modifier
                // - 스크롤 ID 타입이 모듈의 Item과 다름
                // - 결론: .scrollPosition은 "이 뷰의 스크롤을 어떻게 기억할 것인가"이므로 콘텐츠 소유자(WeekMealScreen)의 책임이 맞음.
                .scrollPosition(id: positionIDBinding, anchor: .top)
            }
        }
    }

    @ViewBuilder
    func dayContent(for date: Date, outerColumns: Int = 1) -> some View {
        let day = Calendar.kst.startOfDay(for: date)
        DayMealCard(
            date: day,
            dayMeal: mealStore.meal(for: day),
            preferredColumns: outerColumns >= 2 ? 1 : nil
        )
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mealStore = MealStore()
    let container = DayMealPreviewHelper.previewContainer(type: .normal)

    WeekMealScreen()
        .environment(mealStore)
        .onAppear {
            do {
                try mealStore.load(modelContext: ModelContext(container))
            } catch {
                print("Failed to load preview data: \(error)")
            }
        }
}
