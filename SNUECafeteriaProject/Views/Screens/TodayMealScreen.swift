//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct TodayMealScreen: View {
    @Environment(MealStore.self) private var mealStore

    private enum ShowingMeal: CaseIterable {
        case today, tomorrow

        var title: LocalizedStringKey {
            switch self {
            case .today: "오늘의 식단"
            case .tomorrow: "내일의 식단"
            }
        }
        
        var dayPrefix: String {
            switch self {
            case .today: "오늘"
            case .tomorrow: "내일"
            }
        }

        func meal(from store: MealStore) -> DayMeal? {
            switch self {
            case .today: store.todayMeal
            case .tomorrow: store.tomorrowMeal
            }
        }
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
                    contentView(meal).tag(meal)
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
                        let meal = showingMeal.meal(from: mealStore)
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
            .sheet(item: $shareableImage) { item in
                SharePreviewSheet(image: item.uiImage)
            }
        } // NavigationStack
    }

    @ViewBuilder
    private func contentView(_ showingMeal: ShowingMeal) -> some View {
        let meal = showingMeal.meal(from: mealStore)

        if let meal {
            if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                let title = meal.isHoliday ? "\(showingMeal.dayPrefix)은 휴무일입니다" : "\(showingMeal.dayPrefix)의 식단 없음"
                let image = meal.isHoliday ? "moon.zzz" : "fork.knife"
                let description = meal.isHoliday ? "식당 운영을 하지 않습니다." : "등록된 식단 정보가 없습니다."
                
                ContentUnavailableView(
                    title,
                    systemImage: image,
                    description: Text(description)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DateLabelText(date: meal.date)
                            .padding(.horizontal, 4)

                        DayMealCardsView(dayMeal: meal)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        } else {
            ContentUnavailableView(
                "\(showingMeal.dayPrefix)의 식단 없음",
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
