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

    @State private var showingMeal: ShowingMeal = .today
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // 두 페이지를 가로로 나란히 배치하고 offset으로 슬라이드 전환
                    HStack(spacing: 0) {
                        contentView(.today)
                            .frame(width: geo.size.width, height: geo.size.height)
                        contentView(.tomorrow)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .frame(width: geo.size.width, alignment: .leading)
                    .offset(x: (showingMeal == .today ? 0 : -geo.size.width) + dragOffset)

                    // 제스처 감지하는 투명 레이어
                    HorizontalEdgeDragGestrueLayer { translation, isEnded in
                        print("L -> R")
                        // L→R: 내일 → 오늘로 이동
                        if isEnded {
                            withAnimation(.interpolatingSpring(stiffness: 280, damping: 28)) {
                                if dragOffset > geo.size.width / 3 || translation > geo.size.width / 3 {
                                    showingMeal = .today
                                }
                                dragOffset = 0
                            }
                        } else {
                            guard showingMeal == .tomorrow else { return }
                            dragOffset = max(0, translation)
                        }
                    } onDraggedFromRightToLeft: { translation, isEnded in
                        print("R -> L")
                        // R→L: 오늘 → 내일로 이동
                        if isEnded {
                            withAnimation(.interpolatingSpring(stiffness: 280, damping: 28)) {
                                if dragOffset < -(geo.size.width / 3) || translation < -(geo.size.width / 3) {
                                    showingMeal = .tomorrow
                                }
                                dragOffset = 0
                            }
                        } else {
                            guard showingMeal == .today, tomorrowMeal != nil else { return }
                            dragOffset = min(0, translation)
                        }
                    }

                    VStack {
                        Spacer()
                        Picker("", selection: Binding(
                            get: { showingMeal },
                            set: { newValue in
                                withAnimation(.interpolatingSpring(stiffness: 280, damping: 28)) {
                                    showingMeal = newValue
                                }
                            }
                        )) {
                            ForEach(ShowingMeal.allCases, id: \.self) { meal in
                                Text(meal.title)
                                    .fontWeight(showingMeal == meal ? .bold : .regular)
                                    .tag(meal)
                            }
                        }
                        .frame(width: geo.size.width * 0.6)
                        .pickerStyle(.segmented)
                        .padding(.bottom)
                    }
                }
                .clipped()
            } // GeometryReader
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(showingMeal.title)
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
                    LazyVGrid(columns: columns, spacing: 16) {
                        if meal.hasLunch {
                            MealCardView(dayMeal: meal, mealType: .lunch)
                        }
                        if meal.hasDinner {
                            MealCardView(dayMeal: meal, mealType: .dinner)
                        }
                    }
                    .padding()
                    .padding(.bottom, 56)
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

struct HorizontalEdgeDragGestrueLayer: View {
    typealias DragHandler = (_ translation: Double, _ isEnded: Bool) -> Void

    let onDraggedFromLeftToRight: DragHandler
    let onDraggedFromRightToLeft: DragHandler

    private let dragDistance: CGFloat = 10

    // 현재 활성화된 드래그 방향 (true = L→R, false = R→L, nil = 없음)
    @State private var activeDirection: Bool? = nil

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let width = value.translation.width
                        if width > dragDistance {
                            activeDirection = true
                            onDraggedFromLeftToRight(width, false)
                            print(#function, "width > dragDistance")
                        } else if width < -dragDistance {
                            activeDirection = false
                            onDraggedFromRightToLeft(width, false)
                            print(#function, "width < -dragDistance")
                        }
                    }
                    .onEnded { value in
                        // 활성 방향의 핸들러만 호출, predictedEndTranslation으로 velocity 반영
                        if activeDirection == true {
                            onDraggedFromLeftToRight(value.predictedEndTranslation.width, true)
                        } else if activeDirection == false {
                            onDraggedFromRightToLeft(value.predictedEndTranslation.width, true)
                        }
                        activeDirection = nil
                    }
            )
            .frame(maxWidth: .infinity)
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
