//
//  HorizontalPageSwipeView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

// MARK: - HorizontalPageSwipeView

/// 3-pane 수평 스와이프 네비게이션 컨테이너.
///
/// `[이전 | 현재 | 다음]` pane을 나란히 렌더링하고 드래그 제스처로 항목 간 이동을 처리한다.
///
/// **드래그 기반 이동:**
/// - 화면 너비의 35% 초과 드래그 또는 속도 500 pt/s 이상의 flick으로 전환
/// - 전환 중 입력된 다음 스와이프는 큐에 저장해 완료 직후 즉시 실행 (연속 빠른 스와이프 지원)
///
/// **프로그래매틱 이동 (`programmaticTarget`):**
/// - 툴바·시트 등 외부에서 `programmaticTarget` 바인딩에 목적지를 설정하면 슬라이드 인 애니메이션 실행
/// - 전환 완료 후 자동으로 `nil`로 초기화됨
///
/// **스크롤 비활성화:**
/// - 수평 드래그 중·전환 중에는 content 내부 ScrollView를 자동으로 비활성화
/// - content 뷰에서 별도로 처리할 필요 없음
///
/// - Note: `Item`은 `Comparable & Hashable`을 만족해야 한다.
///   `Comparable`은 이전/다음 방향을 판별하는 데 사용된다.
public struct HorizontalPageSwipeView<Item: Comparable & Hashable, Content: View>: View {
    @Binding private var currentItem: Item
    private let prevItem: Item?
    private let nextItem: Item?
    private let programmaticTarget: Binding<Item?>?
    @ViewBuilder private let content: (Item) -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var viewWidth: CGFloat = 390
    @State private var isNavigating: Bool = false
    @State private var dragAxis: DragAxis? = nil
    @State private var pendingNavigation: Bool? = nil
    /// 툴바/시트 전환 시 인접 pane에 표시할 임시 목적지 항목
    @State private var transitionItem: Item? = nil

    // MARK: - Init

    /// 드래그 전환 전용 초기화.
    /// - Parameters:
    ///   - currentItem: 현재 표시 중인 항목의 바인딩.
    ///   - prevItem: 이전 방향 항목. `nil`이면 이전 방향 드래그를 차단한다.
    ///   - nextItem: 다음 방향 항목. `nil`이면 다음 방향 드래그를 차단한다.
    ///   - content: 각 항목에 대한 콘텐츠 뷰 빌더.
    public init(
        currentItem: Binding<Item>,
        prevItem: Item?,
        nextItem: Item?,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        _currentItem = currentItem
        self.prevItem = prevItem
        self.nextItem = nextItem
        self.programmaticTarget = nil
        self.content = content
    }

    /// 프로그래매틱 이동을 포함한 초기화.
    /// - Parameters:
    ///   - currentItem: 현재 표시 중인 항목의 바인딩.
    ///   - prevItem: 이전 방향 항목. `nil`이면 이전 방향 드래그를 차단한다.
    ///   - nextItem: 다음 방향 항목. `nil`이면 다음 방향 드래그를 차단한다.
    ///   - programmaticTarget: 툴바·시트에서 임의 목적지로 이동할 때 설정하는 바인딩.
    ///     뷰가 전환을 완료하면 자동으로 `nil`로 초기화된다.
    ///   - content: 각 항목에 대한 콘텐츠 뷰 빌더.
    public init(
        currentItem: Binding<Item>,
        prevItem: Item?,
        nextItem: Item?,
        programmaticTarget: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        _currentItem = currentItem
        self.prevItem = prevItem
        self.nextItem = nextItem
        self.programmaticTarget = programmaticTarget
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                content(leftPaneItem)
                    .scrollDisabled(dragAxis == .horizontal || isNavigating)
                    .frame(width: geo.size.width)
                content(currentItem)
                    .scrollDisabled(dragAxis == .horizontal || isNavigating)
                    .frame(width: geo.size.width)
                content(rightPaneItem)
                    .scrollDisabled(dragAxis == .horizontal || isNavigating)
                    .frame(width: geo.size.width)
            }
            .offset(x: -geo.size.width + dragOffset)
            .onAppear { viewWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, new in
                viewWidth = new
                dragOffset = 0
            }
        }
        .clipped()
        .simultaneousGesture(dragGesture)
        .onChange(of: programmaticTarget?.wrappedValue) { _, newTarget in
            guard let target = newTarget else { return }
            navigateTo(target)
        }
    }
}

// MARK: - Pane Items

private extension HorizontalPageSwipeView {
    /// 왼쪽 pane에 표시할 항목.
    /// 프로그래매틱 전환 중 목적지가 이전 방향이면 해당 항목을 표시.
    var leftPaneItem: Item {
        if let t = transitionItem, t < currentItem { return t }
        return prevItem ?? currentItem
    }

    /// 오른쪽 pane에 표시할 항목.
    /// 프로그래매틱 전환 중 목적지가 다음 방향이면 해당 항목을 표시.
    var rightPaneItem: Item {
        if let t = transitionItem, t > currentItem { return t }
        return nextItem ?? currentItem
    }
}

// MARK: - Gesture

private extension HorizontalPageSwipeView {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // 첫 이벤트: 방향만 결정하고 offset은 아직 건드리지 않음
                // isNavigating 여부와 관계없이 항상 축을 결정해야
                // 두 번째 제스처의 onEnded에서 축 정보가 nil이 되는 문제를 방지
                if dragAxis == nil {
                    let h = abs(value.translation.width)
                    let v = abs(value.translation.height)
                    dragAxis = h > v ? .horizontal : .vertical
                    return
                }
                guard !isNavigating else { return }
                guard dragAxis == .horizontal else { return }
                let dx = value.translation.width
                if dx > 0 && prevItem == nil { return }
                if dx < 0 && nextItem == nil { return }
                dragOffset = dx
            }
            .onEnded { value in
                let axis = dragAxis
                dragAxis = nil

                let translation = value.translation.width
                let velocity = value.velocity.width
                let posThreshold = viewWidth * 0.35
                let velThreshold: CGFloat = 500
                let shouldGoForward = axis == .horizontal && (translation < -posThreshold || velocity < -velThreshold)
                let shouldGoBackward = axis == .horizontal && (translation > posThreshold || velocity > velThreshold)

                if isNavigating {
                    // 전환 중 발생한 스와이프는 큐에 저장해 전환 완료 후 즉시 실행
                    if shouldGoForward { pendingNavigation = true }
                    else if shouldGoBackward { pendingNavigation = false }
                    return
                }

                if shouldGoForward {
                    commitNavigation(forward: true)
                } else if shouldGoBackward {
                    commitNavigation(forward: false)
                } else {
                    withAnimation(.spring(bounce: 0)) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - Navigation

private extension HorizontalPageSwipeView {
    /// 드래그 제스처 완료 후 인접 항목으로 슬라이드 전환.
    /// 해당 방향에 항목이 없으면 원위치로 스냅백.
    func commitNavigation(forward: Bool) {
        guard !isNavigating else { return }
        guard let targetItem = forward ? nextItem : prevItem else {
            withAnimation(.spring) { dragOffset = 0 }
            return
        }
        isNavigating = true
        // bounce: 0 → 오버슈트 없이 부드럽게 슬라이드 완료
        withAnimation(.spring(duration: 0.3, bounce: 0)) {
            dragOffset = forward ? -viewWidth : viewWidth
        }
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            await MainActor.run {
                let pending = pendingNavigation
                // animation: nil → scrollPosition(id:)가 애니메이션 없이 즉시 적용됨
                withTransaction(Transaction(animation: nil)) {
                    currentItem = targetItem
                    dragOffset = 0
                    isNavigating = false
                    pendingNavigation = nil
                }
                // 전환 중 입력된 다음 스와이프가 있으면 즉시 연속 실행
                if let next = pending {
                    commitNavigation(forward: next)
                }
            }
        }
    }

    /// 툴바/시트에서 임의 목적지로 슬라이드 전환.
    /// `transitionItem`으로 인접 pane 내용을 목적지로 덮어쓴 후 슬라이드 인.
    func navigateTo(_ target: Item) {
        programmaticTarget?.wrappedValue = nil
        guard !isNavigating else { return }
        guard target != currentItem else { return }
        let forward = target > currentItem
        isNavigating = true
        transitionItem = target
        withAnimation(.spring) {
            dragOffset = forward ? -viewWidth : viewWidth
        }
        Task {
            try? await Task.sleep(for: .seconds(0.31))
            await MainActor.run {
                withTransaction(Transaction(animation: nil)) {
                    transitionItem = nil
                    currentItem = target
                    dragOffset = 0
                    isNavigating = false
                }
            }
        }
    }
}

// MARK: - DragAxis

private extension HorizontalPageSwipeView {
    enum DragAxis { case horizontal, vertical }
}
