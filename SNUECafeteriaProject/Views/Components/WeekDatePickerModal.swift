//
//  WeekDatePickerModal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI
import SNUECafeteriaShared

struct WeekDatePickerModal: View {
    let initialDate: Date
    let availableDates: Set<Date>
    var onSelectedWeek: (Date) -> Void

    @State private var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    /// 선택 가능한 날짜 범위 (availableDates의 최솟값 ~ 최솟값(오늘, availableDates 최댓값))
    private var datePickerRange: ClosedRange<Date> {
        guard let earliest = availableDates.min() else {
            return .distantPast ... Date()
        }
        let latest = max(availableDates.max() ?? Date(), Date())
        return earliest ... latest
    }

    init(
        initialDate: Date,
        availableDates: Set<Date>,
        onSelectedWeek: @escaping (Date) -> Void
    ) {
        self.initialDate = initialDate
        self.availableDates = availableDates
        self.onSelectedWeek = onSelectedWeek
        _selectedDate = .init(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "날짜를 선택해 주간 식단 확인",
                    selection: $selectedDate,
                    in: datePickerRange,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(height: 360)
                .onChange(of: selectedDate) { _, _ in
                    onSelectedWeek(selectedDate)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("날짜를 선택해 주간 식단 확인")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(450)])
            .toolbar {
                ConfirmToolbarButton {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    WeekDatePickerModal(initialDate: .now, availableDates: []) { date in
        print("selectedDate: \(DateFormatter.kstDash.string(from: date))")
    }
    .environment(\.timeZone, TimeZone(identifier: "Asia/Seoul")!)
}
