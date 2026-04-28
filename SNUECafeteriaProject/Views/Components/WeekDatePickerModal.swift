//
//  WeekDatePickerModal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI

// TODO: 전체 데이터 가져와서 데이터가 없는 주는 선택 못하게 하기
struct WeekDatePickerModal: View {
    let initialDate: Date
    /// 선택된 날짜가 포함된 주의 일요일부터 토요일까지의 범위 및 선택된 날짜를 매개변수로 받는 클로저
    var onSelectedWeek: ((range: ClosedRange<Date>, date: Date)) -> Void

    @State private var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    /// 선택된 날짜가 포함된 주의 일요일부터 토요일까지의 범위를 반환하는 계산된 프로퍼티
    /// ## 작동 방식
    /// 1) 선택된 날짜에서 일요일 구하고
    /// 2) 일요일에서 6일 더해서 토요일까지 구하고
    /// 3) 일요일...토요일 ClosedRange 반환
    private var selectedWeekRange: ClosedRange<Date> {
        // 타임존을 서울로 우선 설정
        var calendar = Calendar.current
        calendar.timeZone = .init(identifier: "Asia/Seoul") ?? .autoupdatingCurrent

        // 현재 선택된 날짜의 요일 구하기 (일요일=1, 월요일=2, ..., 토요일=7)
        let weekday = calendar.component(.weekday, from: selectedDate)
        // 일요일까지 며칠을 빼야 하는지 계산
        let daysToSubtract = (weekday - 1) % 7
        // 타임존을 고려하여 일요일 자정 계산
        let sunday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!)
        let saturday = calendar.date(byAdding: .day, value: 6, to: sunday)!

        return sunday ... saturday
    }

    init(
        initialDate: Date,
        onSelectedWeek: @escaping ((range: ClosedRange<Date>, date: Date)) -> Void
    ) {
        self.initialDate = initialDate
        self.onSelectedWeek = onSelectedWeek
        _selectedDate = .init(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "날짜로 확인할 주 선택",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(height: 360) // 1차 고정
                .onChange(of: selectedDate) { _, _ in
                    onSelectedWeek((selectedWeekRange, selectedDate))
                }
                
                Spacer()
            }
            .padding(.horizontal)

            .navigationTitle("날짜로 확인할 주 선택")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(450)]) // 시트 높이를 명시적으로 지정해야 DatePicker가 업데이트될 때 높이가 고정됨
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WeekDatePickerModal(initialDate: .now) { range, _ in
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        print(
            "weekRange: \(formatter.string(from: range.lowerBound)) ~ \(formatter.string(from: range.upperBound))"
        )
    }
    .environment(\.timeZone, TimeZone(identifier: "Asia/Seoul")!)
}
