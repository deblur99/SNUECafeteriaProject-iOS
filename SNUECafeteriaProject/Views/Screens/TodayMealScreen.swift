//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#endif

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
            MealContentUnavailableView(
                title: "\(page.dayPrefix)의 식단 없음",
                systemImage: "fork.knife",
                description: "등록된 식단 정보가 없습니다."
            )
        }
    }

    @ViewBuilder
    private func unavailableView(for meal: DayMeal) -> some View {
        if meal.isHoliday {
            MealContentUnavailableView(
                title: "\(page.dayPrefix)은 휴무일입니다",
                systemImage: "moon.zzz",
                description: "식당 운영을 하지 않습니다."
            )
        } else {
            MealContentUnavailableView(
                title: "\(page.dayPrefix)의 식단 없음",
                systemImage: "fork.knife",
                description: "등록된 식단 정보가 없습니다."
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
    #if os(macOS)
    @State private var contentOpacity = 1.0
    @State private var isPeriodTransitioning = false
    #endif

    var body: some View {
        NavigationStack {
            mealPager
                .background(Color.groupedBackground)
                .inlineNavigationTitle()
                .toolbar(content: toolbarContent)
                .sheet(item: $shareableImage) { item in
                    SharePreviewSheet(content: item)
                }
        }
    }

    @ViewBuilder
    private var mealPager: some View {
        #if os(iOS)
        // iOS: 페이지 스와이프 + 페이지 내부 ScrollView (기존 동작)
        TabView(selection: $showingMeal) {
            ForEach(ShowingMeal.allCases, id: \.self) { page in
                TodayMealPageView(page: page, meal: page.meal(from: mealRepository))
                    .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        TodayMealPageView(page: showingMeal, meal: showingMeal.meal(from: mealRepository))
            .id(showingMeal)
            .animation(nil, value: showingMeal)
            .opacity(contentOpacity)
        #endif
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("", selection: showingMealPickerBinding) {
                ForEach(ShowingMeal.allCases, id: \.self) { meal in
                    Text(meal.title).tag(meal)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
            #if os(macOS)
            .disabled(isPeriodTransitioning)
            #endif
            .onAppear { configureSegmentedAppearance() }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("공유", systemImage: "square.and.arrow.up") {
                shareCurrentMeal()
            }
        }
    }

    private var showingMealPickerBinding: Binding<ShowingMeal> {
        #if os(macOS)
        Binding(
            get: { showingMeal },
            set: { changeShowingMeal(to: $0) }
        )
        #else
        $showingMeal
        #endif
    }

    // MARK: Helpers

    #if os(macOS)
    private func changeShowingMeal(to newValue: ShowingMeal) {
        guard newValue != showingMeal, !isPeriodTransitioning else { return }
        isPeriodTransitioning = true
        Task { @MainActor in
            await MealPeriodTransition.run(opacity: $contentOpacity) {
                showingMeal = newValue
            }
            isPeriodTransitioning = false
        }
    }
    #endif

    /// .pickerStyle(.segmented)은 UISegmentedControl로 렌더링되므로
    /// SwiftUI Text modifier가 적용되지 않음 → UIKit appearance API 사용
    private func configureSegmentedAppearance() {
        #if os(iOS)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 15, weight: .regular)],
            for: .normal
        )
        #endif
    }

    private func shareCurrentMeal() {
        guard let meal = showingMeal.meal(from: mealRepository) else { return }
        shareableImage = MealShareImageFactory.makeShareableImage(
            for: meal,
            mealRepository: mealRepository
        )
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
