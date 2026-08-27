//
//  SharePreviewSheet.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

private enum SharePreviewMode {
    case image
    case text

    mutating func toggle() {
        self = self == .image ? .text : .image
    }

    var toolbarSystemImage: String {
        switch self {
        case .image: "text.alignleft"
        case .text: "photo"
        }
    }

    var toolbarAccessibilityLabel: String {
        switch self {
        case .image: "텍스트 미리보기"
        case .text: "이미지 미리보기"
        }
    }
}

/// 공유할 이미지·텍스트를 미리보기로 제공하는 시트
struct SharePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let content: ShareableImage
    @State private var previewMode: SharePreviewMode = .image
    /// 텍스트 공유용 임시 파일. ShareLink(item: URL)은 경로의 파일명을 그대로 쓴다.
    @State private var textShareURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    switch previewMode {
                    case .image:
                        Image(uiImage: content.uiImage)
                            .resizable()
                            .scaledToFit()
                    case .text:
                        TextField("", text: .constant(content.shareText), axis: .vertical)
                            .lineLimit(nil)
                            .textFieldStyle(.plain)
                            .disabled(true)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("공유 미리보기")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                shareButton
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        previewMode.toggle()
                    } label: {
                        Image(systemName: previewMode.toolbarSystemImage)
                    }
                    .accessibilityLabel(previewMode.toolbarAccessibilityLabel)
                }
            }
            .task(id: content.id) {
                textShareURL = try? TextShareFileWriter.write(
                    text: content.shareText,
                    fileName: content.textFilename
                )
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        switch previewMode {
        case .image:
            ShareLink(
                item: TransferableImage(uiImage: content.uiImage, fileName: content.filename),
                preview: SharePreview(
                    "서울교대 학식 메뉴",
                    image: Image(uiImage: content.uiImage)
                )
            ) {
                shareLabel
            }
            .buttonStyle(.glassProminent)
        case .text:
            if let textShareURL {
                ShareLink(
                    item: textShareURL,
                    preview: SharePreview("서울교대 학식 메뉴")
                ) {
                    shareLabel
                }
                .buttonStyle(.glassProminent)
            } else {
                shareLabel
                    .frame(maxWidth: .infinity)
                    .opacity(0.4)
            }
        }
    }

    private var shareLabel: some View {
        Label("공유하기", systemImage: "square.and.arrow.up")
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
}

/// ShareLink에서 UIImage를 전달하기 위한 Transferable 래퍼
private struct TransferableImage: Transferable {
    let uiImage: UIImage
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.uiImage.pngData() else {
                throw TransferError.conversionFailed
            }
            return data
        }
        .suggestedFileName { item in
            item.fileName
        }
    }

    private enum TransferError: Error {
        case conversionFailed
    }
}

private enum TextShareFileWriter {
    static func write(text: String, fileName: String) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try Data(text.utf8).write(to: fileURL, options: .atomic)
        return fileURL
    }
}

#Preview {
    SharePreviewSheet(
        content: ShareableImage(
            uiImage: UIImage(named: "today_meal_sample")!,
            shareDate: .now,
            shareText: MealShareFormatter.text(for: CachedDayMeal.sample().first!)
        )
    )
}
