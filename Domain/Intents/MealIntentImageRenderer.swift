//
//  MealIntentImageRenderer.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import CGImagePNGKit
import SwiftUI
import UniformTypeIdentifiers

/// 스니펫 뷰를 PNG `IntentFile`로 렌더링하는 헬퍼.
/// `ImageRenderer.cgImage` + ImageIO로 iOS/macOS 공통 경로를 쓴다.
@MainActor
func renderMealSnippet<V: View>(_ view: V, filename: String) throws(AppIntentError) -> IntentFile {
    let renderer = ImageRenderer(content: view)
    renderer.proposedSize = .init(width: MealShareExportView.exportWidth, height: nil)
    renderer.scale = 3.0

    guard let cgImage = renderer.cgImage,
          let data = CGImagePNGKit.pngData(from: cgImage)
    else {
        throw .renderFailed
    }
    return IntentFile(data: data, filename: filename, type: .png)
}
