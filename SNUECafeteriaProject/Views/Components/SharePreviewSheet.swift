//
//  SharePreviewSheet.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// 공유할 이미지를 미리보기로 제공하는 시트
struct SharePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            // 이미지 미리보기
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("공유 미리보기")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                ShareLink(
                    item: TransferableImage(uiImage: image),
                    preview: SharePreview(
                        "서울교대 학식 메뉴",
                        image: Image(uiImage: image)
                    )
                ) {
                    Label("공유하기", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: 320)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// ShareLink에서 UIImage를 전달하기 위한 Transferable 래퍼
private struct TransferableImage: Transferable {
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.uiImage.pngData() else {
                throw TransferError.conversionFailed
            }
            return data
        }
    }

    private enum TransferError: Error {
        case conversionFailed
    }
}

#Preview {
    SharePreviewSheet(image: UIImage(named: "today_meal_sample")!)
}
