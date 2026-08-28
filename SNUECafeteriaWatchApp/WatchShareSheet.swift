//
//  WatchShareSheet.swift
//  SNUECafeteriaWatchApp
//

import SwiftUI

struct WatchShareSheet: View {
    let meal: CachedDayMeal
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        MealShareFormatter.text(for: meal)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(DateFormatter.longDateLabel.string(from: meal.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(shareText)
                    .font(.footnote)
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ShareLink(
                    item: shareText,
                    subject: Text("서울교대 학식 메뉴"),
                    message: Text(shareText),
                    preview: SharePreview("서울교대 학식 메뉴")
                ) {
                    Label("공유", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("공유")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기", systemImage: "xmark") {
                    dismiss()
                }
            }
        }
    }
}
