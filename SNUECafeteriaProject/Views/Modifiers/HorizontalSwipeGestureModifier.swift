//
//  HorizontalSwipeGestureModifier.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI

/// 수평 스와이프 제스처를 뷰에 추가하는 ViewModifier.
///
/// `DragGesture`를 기반으로 하며, 드래그 각도가 수평(|dx| > |dy|)일 때만 반응합니다.
/// `.simultaneousGesture`를 사용해 하위 뷰(ScrollView 등)의 제스처 인식을 방해하지 않습니다.
struct HorizontalSwipeGestureModifier: ViewModifier {
    typealias DragHandler = (_ translation: CGFloat, _ isEnded: Bool) -> Void

    let onDraggedLeftToRight: DragHandler
    let onDraggedRightToLeft: DragHandler

    private let minimumDistance: CGFloat = 10

    /// true = L→R, false = R→L, nil = 비활성
    @State private var activeDirection: Bool? = nil

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: minimumDistance)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        // 수직 드래그는 하위 ScrollView에 전달
                        guard abs(dx) > abs(dy) else { return }

                        if dx > 0 {
                            activeDirection = true
                            onDraggedLeftToRight(dx, false)
                        } else {
                            activeDirection = false
                            onDraggedRightToLeft(dx, false)
                        }
                    }
                    .onEnded { value in
                        // velocity 반영을 위해 predictedEndTranslation 사용
                        switch activeDirection {
                        case true:
                            onDraggedLeftToRight(value.predictedEndTranslation.width, true)
                        case false:
                            onDraggedRightToLeft(value.predictedEndTranslation.width, true)
                        case nil:
                            break
                        }
                        activeDirection = nil
                    }
            )
    }
}

extension View {
    func horizontalSwipeGesture(
        onLeftToRight: @escaping HorizontalSwipeGestureModifier.DragHandler,
        onRightToLeft: @escaping HorizontalSwipeGestureModifier.DragHandler
    ) -> some View {
        modifier(HorizontalSwipeGestureModifier(
            onDraggedLeftToRight: onLeftToRight,
            onDraggedRightToLeft: onRightToLeft
        ))
    }
}
