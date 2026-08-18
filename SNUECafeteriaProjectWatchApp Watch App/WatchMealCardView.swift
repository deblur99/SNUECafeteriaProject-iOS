//
//  WatchMealCardView.swift
//  SNUECafeteriaProjectWatchApp Watch App
//
//  Created by 한현민 on 6/8/26.
//

import SwiftUI
import SNUECafeteriaShared

struct WatchMealCardView: View {
    let mealType: MealType
    let items: [CachedMenuItem]
    let isHoliday: Bool
    var isHighlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mealType.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(mealType.color, in: Capsule())

            if isHoliday {
                Text("휴무일")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if items.isEmpty {
                Text("식단 없음")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.name) { item in
                    Text(item.name)
                        .font(.footnote)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(mealType.color, lineWidth: 2)
            }
        }
    }
}
