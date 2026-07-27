//
//  PhoneWatchMealSyncService.swift
//  SNUECafeteriaProject
//

import Foundation
import WatchConnectivity

/// iPhone에서 Watch로 App Group 식단 캐시를 전달한다.
///
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 환경에서는 WCSessionDelegate가
/// MainActor로 추론되면, 프레임워크가 백그라운드에서 콜백할 때
/// `_swift_task_checkIsolatedSwift`로 크래시한다. 그래서 이 타입은 반드시 nonisolated.
nonisolated final class PhoneWatchMealSyncService: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = PhoneWatchMealSyncService()

    private let stateLock = NSLock()
    private var pendingMealsToPush: [CachedDayMeal]?
    private var isActivationInProgress = false
    private var isActivationScheduled = false

    private override init() {
        super.init()
    }

    /// 포그라운드 진입 시 호출. App Group 초기화와 겹치지 않게 짧게 미룬다.
    func scheduleActivationAndPush() {
        guard WCSession.isSupported() else { return }

        let cached = AppGroupMealCache.load()
        if !cached.isEmpty {
            stateLock.lock()
            pendingMealsToPush = cached
            stateLock.unlock()
        }

        let session = WCSession.default
        if session.activationState == .activated {
            flushPendingIfPossible(session: session)
            return
        }

        stateLock.lock()
        let shouldSchedule = !isActivationScheduled && !isActivationInProgress
        if shouldSchedule { isActivationScheduled = true }
        stateLock.unlock()
        guard shouldSchedule else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.stateLock.lock()
            self.isActivationScheduled = false
            self.stateLock.unlock()
            self.activateIfNeeded()
        }
    }

    func push(_ meals: [CachedDayMeal]) {
        guard WCSession.isSupported() else { return }
        guard WatchMealSync.payload(for: meals) != nil else { return }

        stateLock.lock()
        pendingMealsToPush = meals
        stateLock.unlock()

        let session = WCSession.default
        if session.activationState == .activated {
            flushPendingIfPossible(session: session)
        } else {
            scheduleActivationAndPush()
        }
    }

    func pushCachedMeals() {
        let meals = AppGroupMealCache.load()
        guard !meals.isEmpty else { return }
        push(meals)
    }

    // MARK: - Activation

    private func activateIfNeeded() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        // delegate는 activate 전에 설정. nonisolated 인스턴스여야 한다.
        session.delegate = self

        if session.activationState == .activated {
            flushPendingIfPossible(session: session)
            return
        }

        stateLock.lock()
        let shouldActivate = !isActivationInProgress
        if shouldActivate { isActivationInProgress = true }
        stateLock.unlock()
        guard shouldActivate else { return }

        print("⌚️ WCSession 활성화 요청")
        session.activate()
    }

    // MARK: - WCSessionDelegate (백그라운드 스레드에서 호출될 수 있음)

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        stateLock.lock()
        isActivationInProgress = false
        stateLock.unlock()

        if let error {
            print("⚠️ WCSession 활성화 실패: \(error.localizedDescription)")
            return
        }

        guard activationState == .activated else {
            print("⚠️ WCSession 활성화 상태=\(activationState.rawValue)")
            return
        }

        print("✅ WCSession 활성화 완료 — paired=\(session.isPaired), watchAppInstalled=\(session.isWatchAppInstalled), reachable=\(session.isReachable)")
        flushPendingIfPossible(session: session)
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        stateLock.lock()
        isActivationInProgress = false
        stateLock.unlock()
        scheduleActivationAndPush()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        guard session.activationState == .activated else { return }
        print("⌚️ Watch 상태 변경 — paired=\(session.isPaired), installed=\(session.isWatchAppInstalled)")
        flushPendingIfPossible(session: session)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[WatchMealSync.requestSyncKey] as? Bool == true else {
            replyHandler(WatchMealSync.emptyReply())
            return
        }
        let payload = WatchMealSync.payload(for: AppGroupMealCache.load()) ?? WatchMealSync.emptyReply()
        print("⌚️ Watch sync 요청 응답 — keys=\(payload.keys.sorted())")
        replyHandler(payload)
    }

    // MARK: - Send

    private func flushPendingIfPossible(session: WCSession) {
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else {
            print("⚠️ Watch push 대기 — paired=\(session.isPaired), watchAppInstalled=\(session.isWatchAppInstalled)")
            return
        }

        stateLock.lock()
        let meals = pendingMealsToPush ?? AppGroupMealCache.load()
        pendingMealsToPush = nil
        stateLock.unlock()

        guard !meals.isEmpty else { return }
        sendPayload(meals, session: session)
    }

    private func sendPayload(_ meals: [CachedDayMeal], session: WCSession) {
        guard let payload = WatchMealSync.payload(for: meals) else {
            print("⚠️ Watch 전송 페이로드 생성 실패 (이번 주 식단 없음 또는 용량 초과)")
            return
        }

        do {
            try session.updateApplicationContext(payload)
            let byteCount = (payload[WatchMealSync.contextKey] as? Data)?.count ?? 0
            print("✅ Watch applicationContext 전송 (\(byteCount) bytes)")
        } catch {
            print("⚠️ applicationContext 실패, transferUserInfo로 재시도: \(error.localizedDescription)")
            session.transferUserInfo(payload)
            print("✅ Watch transferUserInfo 큐잉")
        }
    }
}
