//
//  MealCardView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

struct MealCardView: View {
    let dayMeal: DayMeal
    let mealType: MealType

    private var menuItems: [MenuItem] {
        mealType == .lunch ? dayMeal.lunchItems : dayMeal.dinnerItems
    }

    private var mealTypeLabel: String {
        mealType == .lunch ? "중식" : "석식"
    }

    private var accentColor: Color {
        mealType == .lunch ? .orange : .indigo
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: dayMeal.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text(dayMeal.weekdayLabel)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(accentColor, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(mealTypeLabel)
                        .font(.headline)
                }

                Spacer()

                Text(mealTypeLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(accentColor)
                    .background(accentColor.opacity(0.15), in: Capsule())
            }
            .padding()

            Divider()
                .padding(.horizontal)

            // Menu items
            if dayMeal.isHoliday || menuItems.isEmpty {
                Text("식단 정보 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(menuItems, id: \.name) { item in
                        Text(item.name)
                            .font(.subheadline)
                    }
                }
                .padding()
            }
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MealCardView(dayMeal: .sample(), mealType: .lunch)
        .padding()
}
