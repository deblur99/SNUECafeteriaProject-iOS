//
//  WeekDatePickerModal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI

struct WeekDatePickerModal: View {
    private let label = "날짜를 선택해 주간 식단 확인"
    
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
        #if os(macOS)
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.headline)
            
            datePicker
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .fixedSize()
        }
        .padding()
        #else
        NavigationStack {
            VStack {
                datePicker
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .frame(height: 360)

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle(label)
            .inlineNavigationTitle()
            .dismissibleSheetChrome(detents: [.height(450)])
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
        #endif
    }

    private var datePicker: some View {
        DatePicker(
            label,
            selection: $selectedDate,
            in: datePickerRange,
            displayedComponents: [.date]
        )
        .onChange(of: selectedDate) { _, newDate in
            onSelectedWeek(newDate)
        }
    }
}

#Preview {
    WeekDatePickerModal(initialDate: .now, availableDates: []) { date in
        print("selectedDate: \(DateFormatter.kstDash.string(from: date))")
    }
    .environment(\.timeZone, TimeZone(identifier: "Asia/Seoul")!)
}
