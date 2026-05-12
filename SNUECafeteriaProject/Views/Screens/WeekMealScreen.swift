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
    @State private var scrollTarget: Date? = nil

    var body: some View {
        NavigationStack {
            weekContent
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .title) {
                        WeekSelectorView(
                            selectedDate: $selectedDate,
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
                        selectedDate = Calendar.kst.startOfDay(for: date)
                        scrollTarget = selectedDate
                    }
                }
        }
    }
}

// MARK: - Helpers

private extension WeekMealScreen {
    var weekDays: [Date] {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return [] }
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
    @ViewBuilder
    var weekContent: some View {
        let days = weekDays
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
                    .padding()
                }
                // dayContent.id가 변경되면: scrollTarget이 가리키는 dayContent.id에 해당하는 뷰의 상단 영역으로 스크롤 이동
                .scrollPosition(id: $scrollTarget, anchor: .top)
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
