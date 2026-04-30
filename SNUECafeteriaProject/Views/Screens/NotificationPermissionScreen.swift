//
//  NotificationPermissionScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

/// 알림 권한 설정 요청하는 화면
struct NotificationPermissionScreen: View {
    enum Mode {
        case request
        case denied
    }

    @Environment(\.dismiss) private var dismiss

    @State private var currentMode: Mode

    let onPermissionGranted: () -> Void
    let onCancel: () -> Void

    init(
        initialMode: Mode,
        onPermissionGranted: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _currentMode = State(initialValue: initialMode)
        self.onPermissionGranted = onPermissionGranted
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: currentMode == .request ? "bell.fill" : "bell.slash.fill")
                .font(.system(size: 64))
                .foregroundStyle(currentMode == .request ? .orange : .secondary)

            VStack(spacing: 12) {
                Text(currentMode == .request ? "식사 알림을 받아보세요" : "알림 권한이 필요해요")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(currentMode == .request
                    ? "중식·석식 시간에 맞춰 알림을 보내드립니다.\n알림 권한을 허용해 주세요."
                    : "알림 권한이 거부된 상태예요.\n설정 앱에서 알림을 허용해 주세요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                if currentMode == .request {
                    Button {
                        Task {
                            let granted = await NotificationService.shared.requestPermission()
                            if granted {
                                onPermissionGranted()
                                dismiss()
                            } else {
                                currentMode = .denied
                            }
                        }
                    } label: {
                        Text("허용하기")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onCancel()
                        dismiss()
                    } label: {
                        Text("나중에")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                        dismiss()
                    } label: {
                        Text("설정 앱으로 이동")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onCancel()
                        dismiss()
                    } label: {
                        Text("닫기")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    NotificationPermissionScreen(
        initialMode: .request,
        onPermissionGranted: {},
        onCancel: {}
    )
}
