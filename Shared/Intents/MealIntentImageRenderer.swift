//
//  MealIntentImageRenderer.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import SwiftUI
import UniformTypeIdentifiers

/// 스니펫 뷰를 PNG `IntentFile`로 렌더링하는 헬퍼.
/// 단축어에서 이미지 형태로 활용할 수 있도록 `IntentFile`을 반환합니다.
@MainActor
func renderMealSnippet<V: View>(_ view: V, filename: String) throws(AppIntentError) -> IntentFile {
    let renderer = ImageRenderer(content: view)
    renderer.proposedSize = .init(width: MealShareExportView.exportWidth, height: nil)
    renderer.scale = 3.0
    guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else {
        throw .renderFailed
    }
    return IntentFile(data: data, filename: filename, type: .png)
}
