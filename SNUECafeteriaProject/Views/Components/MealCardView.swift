//
//  MealCardView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

struct MealCardView: View {
    @Environment(MealStore.self) private var mealStore

    let dayMeal: DayMeal
    let mealType: MealType

    @State private var isPulsing = false

    private var menuItems: [MenuItem] {
        mealType == .lunch ? dayMeal.sortedLunchItems : dayMeal.sortedDinnerItems
    }

    private var mealTypeLabel: String {
        mealType == .lunch ? "중식" : "석식"
    }

    private var accentColor: Color {
        .mealColor(for: mealType)
    }

    private var willBeServedSoon: Bool {
        guard let mealForNow = mealStore.mealForNow else {
            return false
        }

        return mealForNow.meal == dayMeal && mealForNow.type == mealType
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column: meal type badge
            VStack(spacing: 6) {
                Text(mealTypeLabel)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(accentColor, in: Circle())
            }
            .frame(width: 72)
            .padding(.vertical, 14)
            
            Divider()
                .padding(.vertical, 12)
            
            // Right column: menu items
            Group {
                if menuItems.isEmpty {
                    ContentUnavailableView {
                        Label("식단 정보 없음", systemImage: "fork.knife")
                            .font(.subheadline.weight(.semibold))
                    } description: {
                        Text("해당 시간대 식단이 없습니다.")
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(menuItems, id: \.name) { item in
                            Text(item.name)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 350, maxHeight: 300)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            if willBeServedSoon {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.mealColor(for: mealType)
                            .opacity(isPulsing ? 0.7 : 0.15),
                        lineWidth: 2
                    )
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            if willBeServedSoon { isPulsing = true }
        }
        .onChange(of: willBeServedSoon) { _, newValue in
            isPulsing = newValue
        }
    }
}

struct DayMealCardsView: View {
    let dayMeal: DayMeal
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }
    
    var body: some View {
        Group {
            if dayMeal.isHoliday {
                unavailableCard(
                    title: "오늘은 휴무일입니다",
                    systemImage: "moon.zzz",
                    description: "식당 운영을 하지 않습니다."
                )
            } else if !dayMeal.hasLunch && !dayMeal.hasDinner {
                unavailableCard(
                    title: "오늘의 식단 없음",
                    systemImage: "fork.knife",
                    description: "등록된 식단 정보가 없습니다."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    MealCardView(dayMeal: dayMeal, mealType: .lunch)
                    MealCardView(dayMeal: dayMeal, mealType: .dinner)
                }
            }
        }
        .frame(maxWidth: 750, maxHeight: 700)
    }
    
    private func unavailableCard(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
        } description: {
            Text(description)
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
}

/// 식단 카드들을 이미지로 내보내기 위한 레이아웃 뷰
struct MealShareContent: View {
    let dayMeal: DayMeal

    private var dateText: String {
        return DateFormatter.longDateLabel.string(from: dayMeal.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("서울교대 학식 메뉴")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(dateText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            DayMealCardsView(dayMeal: dayMeal)
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Meal Card View with data") {
    MealCardView(
        dayMeal: .sample().first!,
        mealType: .lunch
    )
    .padding()
    .dayMealPreview(type: .normal)
}

#Preview("Meal Card View with empty") {
    MealCardView(
        dayMeal: .sampleEmpty().first!,
        mealType: .lunch
    )
    .padding()
    .dayMealPreview(type: .empty)
}

#Preview("Day Meal Card View with data") {
    DayMealCardsView(dayMeal: .sample().first!)
        .padding()
        .dayMealPreview(type: .normal)
}

#Preview("Day Meal Card View with empty") {
    DayMealCardsView(dayMeal: .sampleEmpty().first!)
        .padding()
        .dayMealPreview(type: .empty)
}
