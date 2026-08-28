//
//  WatchSharePresentation.swift
//  SNUECafeteriaProject
//

import SwiftUI

/// iPhone에서 Watch 공유 릴레이 payload를 SharePreviewSheet로 표시한다.
struct WatchSharePresentationModifier: ViewModifier {
  @Environment(\.scenePhase) private var scenePhase
  @State private var shareableImage: ShareableImage?

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: .watchShareRelayReceived)) { notification in
        presentShare(from: notification.object as? MealShareRelayPayload)
      }
      .onAppear {
        presentShare(from: PendingWatchShareStore.shared.consume())
      }
      .onChange(of: scenePhase) { _, phase in
        guard phase == .active else { return }
        presentShare(from: PendingWatchShareStore.shared.consume())
      }
      .sheet(item: $shareableImage) { item in
        SharePreviewSheet(content: item)
      }
  }

  private func presentShare(from payload: MealShareRelayPayload?) {
    guard let payload else { return }
    let png = payload.pngData ?? Data()
    shareableImage = ShareableImage(
      pngData: png,
      shareDate: payload.date,
      shareText: payload.text
    )
  }
}

extension View {
  func watchShareRelayPresentation() -> some View {
    modifier(WatchSharePresentationModifier())
  }
}
