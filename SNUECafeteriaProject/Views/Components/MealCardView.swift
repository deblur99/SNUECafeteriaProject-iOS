//
//  MealCardView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

/// 한 끼 메뉴를 표시하는 카드 뷰
/// - 뷰의 크기는 여기에 임의의 .frame을 지정해서 정해도 되고, 외부 컨테이너에 맞춰도 된다.
/// - `isForExport`: true이면 이미지 내보내기용 축소 크기(배지·텍스트·여백)를 적용한다.
private struct MealCardView: View {
    @Environment(MealStore.self) private var mealStore

    let dayMeal: DayMeal
    let mealType: MealType
    var isForExport: Bool = false

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
                    .font(.system(
                        size: isForExport ? 13 : 16,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
                    .frame(
                        width: isForExport ? 36 : 44,
                        height: isForExport ? 36 : 44
                    )
                    .background(accentColor, in: Circle())
            }
            .frame(width: isForExport ? 56 : 72)
            .padding(.vertical, isForExport ? 10 : 14)

            Divider()
                .padding(.vertical, isForExport ? 8 : 12)

            // Right column: menu items
            Group {
                if menuItems.isEmpty {
                    ContentUnavailableView {
                        Label("식단 정보 없음", systemImage: "fork.knife")
                            .font(.system(
                                size: isForExport ? 13 : 15,
                                weight: .semibold
                            ))
                    } description: {
                        Text("해당 시간대 식단이 없습니다.")
                            .font(.system(size: isForExport ? 12 : 13))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: isForExport ? 4 : 6) {
                        ForEach(menuItems, id: \.name) { item in
                            Text(item.name)
                                .font(.system(size: isForExport ? 14 : 15))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(isForExport ? 10 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: isForExport ? 12 : 16)
        )
        .overlay {
            if willBeServedSoon {
                RoundedRectangle(cornerRadius: isForExport ? 12 : 16)
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

/// 하루 메뉴 전체를 표시하는 카드 뷰
private struct DayMealCardsView: View {
    let dayMeal: DayMeal?
    /// nil이면 horizontalSizeClass 기반으로 자동 결정, 값이 있으면 해당 열 수를 강제 적용
    var preferredColumns: Int? = nil
    /// true이면 이미지 내보내기용 축소 크기를 MealCardView에 전달한다.
    var isForExport: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        let count = preferredColumns ?? ((horizontalSizeClass ?? .compact) == .regular ? 2 : 1)
        return count >= 2
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        if dayMeal == nil {
            ContentUnavailableView(
                "식단 정보 없음",
                systemImage: "fork.knife",
                description: Text("해당 날짜의 식단 정보가 없습니다.")
            )
            .foregroundStyle(.secondary)
        } else if dayMeal!.isHoliday {
            unavailableCard(
                title: "\(dayMeal!.isToday ? "오늘은 " : "")휴무일입니다",
                systemImage: "moon.zzz",
                description: "식당 운영을 하지 않습니다."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !dayMeal!.hasLunch && !dayMeal!.hasDinner {
            unavailableCard(
                title: "\(dayMeal!.isToday ? "오늘의 식단 없음" : "식단 정보 없음")",
                systemImage: "fork.knife",
                description: "등록된 식단 정보가 없습니다."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LazyVGrid(columns: columns, spacing: isForExport ? 10 : 16) {
                MealCardView(dayMeal: dayMeal!, mealType: .lunch, isForExport: isForExport)
                MealCardView(dayMeal: dayMeal!, mealType: .dinner, isForExport: isForExport)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
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
        .frame(maxWidth: .infinity, minHeight: 140)
    }
}

/// 날짜 헤더와 식단 카드를 묶은 하루 단위 컨테이너 카드
struct DayMealCard: View {
    let date: Date
    let dayMeal: DayMeal?
    var preferredColumns: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DateLabelText(date: date)
                .padding(.horizontal, 4)

            Divider()

            DayMealCardsView(dayMeal: dayMeal, preferredColumns: preferredColumns)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

/// 식단 카드들을 이미지로 내보내기 위한 레이아웃 뷰
struct MealShareContent: View {
    /// ImageRenderer가 이 너비로 렌더링한다. @3x 기준 1080px 출력.
    static let exportWidth: CGFloat = 360

    let dayMeal: DayMeal

    private var dateText: String {
        return DateFormatter.longDateLabel.string(from: dayMeal.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("서울교대 학식 메뉴")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(dateText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            DayMealCardsView(dayMeal: dayMeal, preferredColumns: 1, isForExport: true)
        }
        .padding(14)
        .frame(width: Self.exportWidth)
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

#Preview("Day Meal Card View with lunch data only") {
    DayMealCardsView(dayMeal: .sampleWithOnlyLunch().first!)
        .padding()
        .dayMealPreview(type: .normal)
}

#Preview("Day Meal Card View with empty") {
    DayMealCardsView(dayMeal: .sampleEmpty().first!)
        .padding()
        .dayMealPreview(type: .empty)
}
