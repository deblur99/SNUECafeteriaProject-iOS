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
    @State private var selectedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var isSheetPresented: Bool = false

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
                    }
                }
        }
    }
}

// MARK: - Helpers

private extension WeekMealScreen {
    var selectedDay: Date {
        Calendar.kst.startOfDay(for: selectedDate)
    }

    var weekDays: [Date] {
        guard let interval = Calendar.kstWeekInterval(for: selectedDay) else { return [] }
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            guard let next = Calendar.kst.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    /// 주어진 너비에 따라 1열 또는 2열 레이아웃을 반환하는 헬퍼 메서드
    func gridColumns(for width: CGFloat) -> [GridItem] {
        let isWideWidth = width >= 768
        return isWideWidth
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
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
                ScrollView {
                    LazyVGrid(columns: gridColumns(for: geometry.size.width), spacing: 0) {
                        ForEach(days, id: \.self) { date in
                            dayContent(for: date)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    func dayContent(for date: Date) -> some View {
        let day = Calendar.kst.startOfDay(for: date)
        VStack(alignment: .leading, spacing: 16) {
            DateLabelText(date: day)
                .padding(.horizontal, 4)
            if let meal = mealStore.meal(for: day) {
                DayMealCardsView(dayMeal: meal)
            } else {
                ContentUnavailableView(
                    "식단 정보 없음",
                    systemImage: "fork.knife",
                    description: Text("해당 날짜의 식단 정보가 없습니다.")
                )
            }
        }
        .padding(.top, 16)
        .padding(.horizontal)
        .padding(.bottom)
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
