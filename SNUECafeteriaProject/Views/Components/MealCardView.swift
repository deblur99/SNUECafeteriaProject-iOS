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
                if dayMeal.isHoliday || menuItems.isEmpty {
                    Text("식단 정보 없음")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        .frame(maxWidth: 600)
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

            if dayMeal.hasLunch {
                MealCardView(dayMeal: dayMeal, mealType: .lunch)
            }
            if dayMeal.hasDinner {
                MealCardView(dayMeal: dayMeal, mealType: .dinner)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    @Previewable @State var mealStore = MealStore()

    MealCardView(
        dayMeal: .sample().first!,
        mealType: .lunch
    )
    .padding()
    .environment(mealStore)
}
