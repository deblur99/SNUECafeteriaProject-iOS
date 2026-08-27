//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

// MARK: - Supporting Types

enum ShowingMeal: CaseIterable {
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

    func meal(from store: MealRepository) -> DayMeal? {
        switch self {
        case .today: store.todayMeal
        case .tomorrow: store.tomorrowMeal
        }
    }
}

// MARK: - Page Content View

/// 오늘 / 내일 탭 하나의 콘텐츠 페이지
private struct TodayMealPageView: View {
    let page: ShowingMeal
    let meal: DayMeal?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if let meal {
            if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                unavailableView(for: meal)
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        DayMealCard(
                            date: meal.date,
                            dayMeal: meal,
                            isShareButtonContained: false,
                            preferredColumns: contentColumns(for: geometry.size.width)
                        )
                        .padding()
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "\(page.dayPrefix)의 식단 없음",
                systemImage: "fork.knife",
                description: Text("등록된 식단 정보가 없습니다.")
            )
        }
    }

    @ViewBuilder
    private func unavailableView(for meal: DayMeal) -> some View {
        if meal.isHoliday {
            ContentUnavailableView(
                "\(page.dayPrefix)은 휴무일입니다",
                systemImage: "moon.zzz",
                description: Text("식당 운영을 하지 않습니다.")
            )
        } else {
            ContentUnavailableView(
                "\(page.dayPrefix)의 식단 없음",
                systemImage: "fork.knife",
                description: Text("등록된 식단 정보가 없습니다.")
            )
        }
    }

    /// regular(아이패드 전체화면) 또는 wide compact(아이폰 가로 ≥ 600pt) → 2열
    /// narrow compact(아이폰 세로, iPad Slide Over) → 1열
    private func contentColumns(for width: CGFloat) -> Int {
        (horizontalSizeClass ?? .compact) == .regular || width >= 600 ? 2 : 1
    }
}

// MARK: - Screen

struct TodayMealScreen: View {
    @Environment(MealRepository.self) private var mealRepository

    @Binding var showingMeal: ShowingMeal
    @State private var shareableImage: ShareableImage?

    var body: some View {
        NavigationStack {
            TabView(selection: $showingMeal) {
                ForEach(ShowingMeal.allCases, id: \.self) { page in
                    TodayMealPageView(page: page, meal: page.meal(from: mealRepository))
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(item: $shareableImage) { item in
                SharePreviewSheet(content: item)
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("", selection: $showingMeal) {
                ForEach(ShowingMeal.allCases, id: \.self) { meal in
                    Text(meal.title).tag(meal)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
            .onAppear { configureSegmentedAppearance() }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("공유", systemImage: "square.and.arrow.up") {
                shareCurrentMeal()
            }
        }
    }

    // MARK: Helpers

    /// .pickerStyle(.segmented)은 UISegmentedControl로 렌더링되므로
    /// SwiftUI Text modifier가 적용되지 않음 → UIKit appearance API 사용
    private func configureSegmentedAppearance() {
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 15, weight: .regular)],
            for: .normal
        )
    }

    private func shareCurrentMeal() {
        guard let meal = showingMeal.meal(from: mealRepository), !meal.isHoliday else { return }
        let renderer = ImageRenderer(
            content: MealShareContent(dayMeal: meal).environment(mealRepository)
        )
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareableImage = ShareableImage(
                uiImage: uiImage,
                shareDate: meal.date,
                shareText: MealShareFormatter.text(for: meal.toCachedModel())
            )
        }
    }
}

// MARK: - Previews

#Preview("Sample Data") {
    TodayMealScreen(showingMeal: .constant(.today))
        .modifier(DayMealPreviewModifier(type: .normal))
}

#Preview("No Data") {
    TodayMealScreen(showingMeal: .constant(.today))
        .modifier(DayMealPreviewModifier(type: .empty))
}

#Preview("Holiday Data") {
    TodayMealScreen(showingMeal: .constant(.today))
        .modifier(DayMealPreviewModifier(type: .holiday))
}
