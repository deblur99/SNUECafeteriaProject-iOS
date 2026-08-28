//
//  SharePreviewSheet.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

private enum SharePreviewMode: Hashable {
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
    /// iOS 텍스트 ShareLink용 임시 파일. 경로의 파일명을 그대로 쓴다.
    /// macOS는 파일 URL 없이 Transferable로 공유하고, 저장만 NSSavePanel을 쓴다.
    @State private var textShareURL: URL?

    var body: some View {
        #if os(macOS)
        macBody
        #else
        iosBody
            .lockedSheetChrome(detents: [.medium])
        #endif
    }

    #if os(macOS)
    private var macBody: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("미리보기 형식", selection: $previewMode) {
                    Text("이미지").tag(SharePreviewMode.image)
                    Text("텍스트").tag(SharePreviewMode.text)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 240)
                .padding(.top, 8)

                ScrollView {
                    previewContent
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
            .frame(minWidth: 420, idealWidth: 480, minHeight: 420)
            .background(Color.groupedBackground.ignoresSafeArea())
            .navigationTitle("공유 미리보기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            // macOS 툴바의 ShareLink는 종종 그려지지 않음 → 하단에서 저장/공유를 분리 배치
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("저장…", systemImage: "square.and.arrow.down") {
                        presentSavePanel()
                    }
                    .buttonStyle(.bordered)

                    macShareLink
                        .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
            }
        }
    }

    @ViewBuilder
    private var macShareLink: some View {
        switch previewMode {
        case .image:
            ShareLink(
                item: TransferableImage(
                    pngData: content.pngData,
                    fileName: content.filename,
                    shareText: content.shareText
                ),
                preview: SharePreview(
                    "서울교대 학식 메뉴",
                    image: content.previewImage
                )
            ) {
                Label("공유", systemImage: "square.and.arrow.up")
            }
        case .text:
            ShareLink(
                item: TransferableText(text: content.shareText, fileName: content.textFilename),
                preview: SharePreview("서울교대 학식 메뉴")
            ) {
                Label("공유", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func presentSavePanel() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        switch previewMode {
        case .image:
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = content.filename
            panel.title = "이미지로 저장"
        case .text:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = content.textFilename
            panel.title = "텍스트로 저장"
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            switch previewMode {
            case .image:
                try content.pngData.write(to: url, options: .atomic)
            case .text:
                try Data(content.shareText.utf8).write(to: url, options: .atomic)
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    #endif

    #if !os(macOS)
    private var iosBody: some View {
        NavigationStack {
            ScrollView {
                previewContent
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .background(Color.groupedBackground.ignoresSafeArea())
            .navigationTitle("공유 미리보기")
            .inlineNavigationTitle()
            .safeAreaInset(edge: .bottom) {
                iosShareButton
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
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
    private var iosShareButton: some View {
        switch previewMode {
        case .image:
            ShareLink(
                item: TransferableImage(
                    pngData: content.pngData,
                    fileName: content.filename,
                    shareText: content.shareText
                ),
                preview: SharePreview(
                    "서울교대 학식 메뉴",
                    image: content.previewImage
                )
            ) {
                shareLabel
            }
            .prominentShareButtonStyle()
        case .text:
            if let textShareURL {
                ShareLink(
                    item: textShareURL,
                    preview: SharePreview("서울교대 학식 메뉴")
                ) {
                    shareLabel
                }
                .prominentShareButtonStyle()
            } else {
                // 파일 준비 전에도 클립보드 Copy용 텍스트는 공유 가능
                ShareLink(
                    item: TransferableText(text: content.shareText, fileName: content.textFilename),
                    preview: SharePreview("서울교대 학식 메뉴")
                ) {
                    shareLabel
                }
                .prominentShareButtonStyle()
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
    #endif

    @ViewBuilder
    private var previewContent: some View {
        switch previewMode {
        case .image:
            content.previewImage
                .resizable()
                .scaledToFit()
        case .text:
            // disabled TextField는 회색으로 고정되므로 Text + primary로 다크모드 가독성 확보
            Text(content.shareText)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// ShareLink에서 PNG + 텍스트(클립보드 Copy)를 전달하기 위한 Transferable 래퍼
private struct TransferableImage: Transferable {
    let pngData: Data
    let fileName: String
    let shareText: String

    static var transferRepresentation: some TransferRepresentation {
        // Copy는 보통 문자열 Proxy를 우선한다.
        ProxyRepresentation(exporting: \.shareText)
        DataRepresentation(exportedContentType: .png) { item in
            item.pngData
        }
        .suggestedFileName { item in
            item.fileName
        }
    }
}

/// 텍스트 공유 — ProxyRepresentation으로 공유 시트의 Copy가 클립보드 문자열로 동작한다.
private struct TransferableText: Transferable {
    let text: String
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.text)
        DataRepresentation(exportedContentType: .utf8PlainText) { item in
            Data(item.text.utf8)
        }
        .suggestedFileName { item in
            item.fileName
        }
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
            pngData: Data(),
            shareDate: .now,
            shareText: MealShareFormatter.text(for: CachedDayMeal.sample().first!)
        )
    )
}
