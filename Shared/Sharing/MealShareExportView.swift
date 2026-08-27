//
//  MealShareExportView.swift
//  Shared
//

import SwiftUI

/// 앱 공유 미리보기·App Intents 이미지 출력에 공통으로 쓰는 내보내기 레이아웃
struct MealShareExportView: View {
    /// ImageRenderer가 이 너비로 렌더링한다. @3x 기준 1080px 출력.
    static let exportWidth: CGFloat = 360

    let meal: CachedDayMeal
    var highlightedMealType: MealType?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("서울교대 학식 메뉴")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DateFormatter.longDateLabel.string(from: meal.date))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if meal.isHoliday {
                Label("휴무일입니다", systemImage: "moon.zzz")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 10) {
                    MealShareCardRow(
                        mealType: .lunch,
                        items: meal.sortedLunchItems.map(\.name),
                        isHoliday: meal.isHoliday,
                        isHighlighted: highlightedMealType == .lunch
                    )
                    MealShareCardRow(
                        mealType: .dinner,
                        items: meal.sortedDinnerItems.map(\.name),
                        isHoliday: meal.isHoliday,
                        isHighlighted: highlightedMealType == .dinner
                    )
                }
            }
        }
        .padding(14)
        .frame(width: Self.exportWidth)
        .background(Color.groupedBackground)
    }
}

/// 가장 가까운 한 끼 식단 내보내기 레이아웃
struct MealShareNearestExportView: View {
    let meal: CachedDayMeal
    let mealType: MealType

    private var items: [String] {
        mealType == .lunch
            ? meal.sortedLunchItems.map(\.name)
            : meal.sortedDinnerItems.map(\.name)
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

            MealShareCardRow(
                mealType: mealType,
                items: items,
                isHoliday: meal.isHoliday,
                isHighlighted: true
            )
        }
        .padding(14)
        .frame(width: MealShareExportView.exportWidth)
        .background(Color.groupedBackground)
    }
}

struct MealShareCardRow: View {
    let mealType: MealType
    let items: [String]
    var isHoliday: Bool = false
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(mealType.label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.mealColor(for: mealType), in: Circle())
                .frame(width: 56)
                .padding(.vertical, 10)

            Divider().padding(.vertical, 8)

            Group {
                if isHoliday {
                    Text("휴무일")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else if items.isEmpty {
                    Text("식단 없음")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 14))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mealColor(for: mealType), lineWidth: 2)
            }
        }
    }
}
