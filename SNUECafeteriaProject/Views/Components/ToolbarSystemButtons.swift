//
//  ToolbarSystemButtons.swift
//  SNUECafeteriaProject
//

import SwiftUI

/// iOS 26+ 시스템 Cancel 버튼. 하위 버전은 텍스트 라벨로 대체한다.
struct CancelToolbarButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if #available(iOS 26.0, *) {
                Button(role: .cancel, action: action)
            } else {
                Button("취소", role: .cancel, action: action)
            }
        }
    }
}

/// iOS 26+ 시스템 Confirm 버튼. 하위 버전은 텍스트 라벨로 대체한다.
struct ConfirmToolbarButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if #available(iOS 26.0, *) {
                Button(role: .confirm, action: action)
            } else {
                Button("완료", action: action)
            }
        }
    }
}
