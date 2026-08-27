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
        #if os(macOS)
        VStack(alignment: .leading, spacing: 12) {
            Text("알림 시간 변경")
                .font(.headline)

            DatePicker(
                "알림 시간 선택",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.stepperField)
            .labelsHidden()

            HStack {
                Spacer()
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("완료") {
                    onSelectedTime(selectedTime)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .fixedSize()
        #else
        NavigationStack {
            DatePicker(
                "알림 시간 선택",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .navigationTitle("알림 시간 선택")
            .inlineNavigationTitle()
            .platformPresentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        onSelectedTime(selectedTime)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
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
        #endif
    }
}

#Preview {
    TimeDatePickerModal(initialTime: .now) { time in
        print("Selected time: \(DateFormatter.hourMinute.string(from: time))")
    }
}
