//
//  MealPeriodTransition.swift
//  Shared
//

import SwiftUI

/// 날짜·주 기간 전환 시 콘텐츠 교체를 가리기 위한 짧은 페이드 (watchOS와 동일 타이밍).
/// 레이아웃 재측정이 보이지 않도록, 완전 비가시 상태에서만 데이터를 바꾸고 정착 후 페이드 인한다.
nonisolated enum MealPeriodTransition {
    static let fadeOut: TimeInterval = 0.12
    static let fadeIn: TimeInterval = 0.16
    /// 교체 직후 LazyVGrid·스크롤 등 레이아웃이 끝나기 전까지 비가시 유지
    static let layoutSettle: TimeInterval = 0.08

    /// 페이드 아웃 → (비가시) 업데이트·레이아웃 정착 → 페이드 인
    @MainActor
    static func run(opacity: Binding<Double>, update: () -> Void) async {
        withAnimation(.easeOut(duration: fadeOut)) {
            opacity.wrappedValue = 0
        }
        try? await Task.sleep(for: .milliseconds(Int(fadeOut * 1000)))

        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            update()
            opacity.wrappedValue = 0
        }

        // 한 프레임 이상 양보해 새 트리 레이아웃이 opacity 0에서 끝나게 한다.
        await Task.yield()
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(Int(layoutSettle * 1000)))

        withAnimation(.easeIn(duration: fadeIn)) {
            opacity.wrappedValue = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(fadeIn * 1000)))
    }
}
