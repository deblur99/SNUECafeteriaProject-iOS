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

    private var dateLabel: String {
        String.shortDateLabel(from: dayMeal.date)
    }

    private var willBeServedSoon: Bool {
        guard let mealForNow = mealStore.mealForNow else {
            return false
        }

        return mealForNow.meal == dayMeal && mealForNow.type == mealType
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

#Preview {
    @Previewable @State var mealStore = MealStore()

    MealCardView(dayMeal: .sample(), mealType: .lunch)
        .padding()
        .environment(mealStore)
}
