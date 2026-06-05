//
//  MealIntentSnippetView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import SwiftUI

// MARK: - 가장 가까운 식단 스니펫

struct NearestMealSnippetView: View {
    let entity: MealEntity
    let mealType: MealType

    private var items: [String] {
        mealType == .lunch ? entity.lunchItems : entity.dinnerItems
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("서울교대 학식 메뉴")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("오늘 \(mealType.label)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mealColor(for: mealType))
            }
            IntentMealCardRow(items: items, mealType: mealType)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - 특정 날짜 식단 스니펫

struct DayMealSnippetView: View {
    let entity: MealEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("서울교대 학식 메뉴")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DateFormatter.longDateLabel.string(from: entity.date))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            if entity.isHoliday {
                Label("휴무일입니다", systemImage: "moon.zzz")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    IntentMealCardRow(items: entity.lunchItems, mealType: .lunch)
                    IntentMealCardRow(items: entity.dinnerItems, mealType: .dinner)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - 공통 식단 카드 행

private struct IntentMealCardRow: View {
    let items: [String]
    let mealType: MealType

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(mealType == .lunch ? "중식" : "석식")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.mealColor(for: mealType), in: Circle())
                .frame(width: 56)
                .padding(.vertical, 10)

            Divider().padding(.vertical, 8)

            if items.isEmpty {
                Text("정보 없음")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items.indices, id: \.self) { i in
                        Text(items[i])
                            .font(.system(size: 14))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
