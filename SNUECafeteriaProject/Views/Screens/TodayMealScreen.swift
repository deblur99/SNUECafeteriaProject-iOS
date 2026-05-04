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

    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if let meal = todayMeal {
                        if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                            ContentUnavailableView(
                                meal.isHoliday ? "오늘은 휴무일입니다" : "오늘의 식단 없음",
                                systemImage: meal.isHoliday ? "moon.zzz" : "fork.knife",
                                description: Text(meal.isHoliday ? "식당 운영을 하지 않습니다." : "등록된 식단 정보가 없습니다.")
                            )
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    if meal.hasLunch {
                                        MealCardView(dayMeal: meal, mealType: .lunch)
                                    }
                                    if meal.hasDinner {
                                        MealCardView(dayMeal: meal, mealType: .dinner)
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

                // 제스처 감지하는 투명 레이어
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("오늘의 식단")
        }
    }
}

struct HorizontalEdgeDragGestrueLayer: View {
    let onDraggedFromLeftToRight: () -> Void
    let onDraggedFromRightToLeft: () -> Void

    // 가장자리 판정 기준 (예: 끝에서 30px 이내)
    private let edgeThreshold: CGFloat = 30
    // 드래그 거리 판정 기준 (예: 50px 이상 밀었을 때)
    private let dragDistance: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .frame(width: 20, height: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let startX = value.startLocation.x  // 드래그 시작 지점
                            let width = value.translation.width  // 얼마 만큼 움직였는지
                            
                            // 1) 왼쪽 끝에서 오른쪽으로: 이동한 거리가 기준보다 크면 왼쪽에서 오른쪽으로
                            if startX < edgeThreshold && width > dragDistance {
                                onDraggedFromLeftToRight()
                            }
                            
                            // 1) 오른쪽 끝에서 왼쪽으로: 이동한 거리가 -기준보다 작으면 오른쪽에서 왼쪽으로
                            else if startX > (geometry.size.width - edgeThreshold)
                                        && width < -dragDistance {
                                onDraggedFromRightToLeft()
                            }
                        }
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
