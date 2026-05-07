//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct TodayMealScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(MealStore.self) private var mealStore

    private var todayMeal: DayMeal? {
        mealStore.todayMeal
    }

    private var tomorrowMeal: DayMeal? {
        mealStore.tomorrowMeal
    }

    private enum ShowingMeal: CaseIterable {
        case today, tomorrow

        var title: LocalizedStringKey {
            switch self {
            case .today: "오늘의 식단"
            case .tomorrow: "내일의 식단"
            }
        }
    }

    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    /// UIImage는 Identifiable이 아니므로 sheet(item:) 사용을 위한 래퍼
    private struct ShareableImage: Identifiable {
        let id = UUID()
        let uiImage: UIImage
    }

    @State private var showingMeal: ShowingMeal = .today
    @State private var shareableImage: ShareableImage?

    var body: some View {
        NavigationStack {
            // TabView를 사용하여 좌우 스크롤 페이지 구현
            TabView(selection: $showingMeal) {
                ForEach(ShowingMeal.allCases, id: \.self) { meal in
                    contentView(meal)
                        .tag(meal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $showingMeal) {
                        ForEach(ShowingMeal.allCases, id: \.self) { meal in
                            Text(meal.title).tag(meal)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 230)
                    .onAppear {
                        // .pickerStyle(.segmented)은 UISegmentedControl로 렌더링되므로
                        // SwiftUI Text modifier가 적용되지 않음 → UIKit appearance API 사용
                        UISegmentedControl.appearance().setTitleTextAttributes(
                            [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)],
                            for: .selected
                        )
                        UISegmentedControl.appearance().setTitleTextAttributes(
                            [.font: UIFont.systemFont(ofSize: 15, weight: .regular)],
                            for: .normal
                        )
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("공유", systemImage: "square.and.arrow.up") {
                        let meal = showingMeal == .today ? todayMeal : tomorrowMeal
                        guard let meal, !meal.isHoliday else { return }

                        let renderer = ImageRenderer(
                            content: MealShareContent(dayMeal: meal)
                                .environment(mealStore)
                        )
                        renderer.scale = 3.0
                        if let uiImage = renderer.uiImage {
                            shareableImage = ShareableImage(uiImage: uiImage)
                        }
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(item: $shareableImage) { item in
                SharePreviewSheet(image: item.uiImage)
            }
        } // NavigationStack
    }

    @ViewBuilder
    private func contentView(_ showingMeal: ShowingMeal) -> some View {
        let meal = switch showingMeal {
        case .today: todayMeal
        case .tomorrow: tomorrowMeal
        }

        if let meal {
            if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                ContentUnavailableView(
                    meal.isHoliday ? "오늘은 휴무일입니다" : "오늘의 식단 없음",
                    systemImage: meal.isHoliday ? "moon.zzz" : "fork.knife",
                    description: Text(meal.isHoliday ? "식당 운영을 하지 않습니다." : "등록된 식단 정보가 없습니다.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DateLabelText(date: meal.date)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 16) {
                            if meal.hasLunch {
                                MealCardView(dayMeal: meal, mealType: .lunch)
                            }
                            if meal.hasDinner {
                                MealCardView(dayMeal: meal, mealType: .dinner)
                            }
                        }
                    }
                    .padding()
                }
            }
        } else {
            ContentUnavailableView(
                "오늘의 식단 없음",
                systemImage: "fork.knife",
                description: Text("등록된 식단 정보가 없습니다.")
            )
        }
    }
}

#Preview("Sample Data") {
    TodayMealScreen()
        .modifier(DayMealPreviewModifier(type: .normal))
}

#Preview("No Data") {
    TodayMealScreen()
        .modifier(DayMealPreviewModifier(type: .empty))
}

#Preview("Holiday Data") {
    TodayMealScreen()
        .modifier(DayMealPreviewModifier(type: .holiday))
}
