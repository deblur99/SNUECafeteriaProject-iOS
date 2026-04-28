//
//  TimeDatePickerModal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI

struct TimeDatePickerModal: View {
    let initialTime: Date
    /// 선택된 시:분을 매개변수로 받는 클로저
    var onSelectedTime: (Date) -> Void

    @State private var selectedTime: Date
    @Environment(\.dismiss) private var dismiss

    init(
        initialTime: Date,
        onSelectedTime: @escaping (Date) -> Void
    ) {
        self.initialTime = initialTime
        self.onSelectedTime = onSelectedTime
        _selectedTime = .init(initialValue: initialTime)
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "알림 시간 선택",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .navigationTitle("알림 시간 선택")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                // 좌측 취소 버튼: 실수로 들어온 경우를 대비해 안정감을 줍니다.
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        onSelectedTime(selectedTime)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .title) {
                    VStack {
                        Text("알림 시간 변경")
                            .font(.headline)

                        Text("완료를 누르면 알림 시간이 변경됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    TimeDatePickerModal(initialTime: .now) { time in
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        print("Selected time: \(formatter.string(from: time))")
    }
}
