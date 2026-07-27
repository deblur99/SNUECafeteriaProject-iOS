//
//  WatchMealSyncService.swift
//  SNUECafeteriaProjectWatchApp Watch App
//

import Foundation
import WatchConnectivity

/// iPhone companion으로부터 식단 캐시를 받아 Watch App Group에 저장한다.
///
/// Default MainActor isolation에서는 WCSessionDelegate 콜백이 백그라운드에서
/// 들어올 때 isolation assert로 크래시할 수 있어 nonisolated로 둔다.
nonisolated final class WatchMealSyncService: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchMealSyncService()

    private let stateLock = NSLock()
    private var mealsUpdatedHandler: (@MainActor @Sendable () -> Void)?
    private var activationContinuations: [CheckedContinuation<Bool, Never>] = []

    /// Watch UI 갱신용. MainActor에서만 실행된다.
    var onMealsUpdated: (@MainActor @Sendable () -> Void)? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return mealsUpdatedHandler
        }
        set {
            stateLock.lock()
            mealsUpdatedHandler = newValue
            stateLock.unlock()
        }
    }

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState == .notActivated {
            session.activate()
            print("⌚️ Watch WCSession 활성화 요청")
        }
    }

    func waitUntilActivated(timeoutNanoseconds: UInt64 = 3_000_000_000) async -> Bool {
        let session = WCSession.default
        if session.activationState == .activated { return true }

        activate()

        return await withCheckedContinuation { continuation in
            stateLock.lock()
            activationContinuations.append(continuation)
            stateLock.unlock()

            Task {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                resumeActivationWaiters(success: WCSession.default.activationState == .activated)
            }
        }
    }

    func requestSyncFromCompanion() async {
        let activated = await waitUntilActivated()
        guard activated else {
            print("⚠️ Watch WCSession 활성화 타임아웃")
            return
        }

        guard WatchCompanionAvailability.isPairedCompanionAvailable else {
            print("⚠️ companion 앱 미설치 — WatchConnectivity 동기화 생략")
            return
        }

        let session = WCSession.default

        if let context = receivedContext(from: session), applyPayloadIfNeeded(context) {
            print("✅ receivedApplicationContext에서 식단 적용")
            notifyMealsUpdated()
            return
        }

        guard session.isReachable else {
            print("⚠️ iPhone unreachable — applicationContext도 비어 있음")
            return
        }

        print("⌚️ iPhone에 sendMessage로 식단 요청")
        await withCheckedContinuation { continuation in
            session.sendMessage([WatchMealSync.requestSyncKey: true], replyHandler: { [weak self] reply in
                guard let self else {
                    continuation.resume()
                    return
                }
                if self.applyPayloadIfNeeded(reply) {
                    print("✅ sendMessage 응답으로 식단 적용")
                    self.notifyMealsUpdated()
                } else {
                    print("⚠️ sendMessage 응답에 식단 없음 — keys=\(reply.keys.sorted())")
                }
                continuation.resume()
            }, errorHandler: { error in
                print("⚠️ iPhone 식단 동기화 요청 실패: \(error.localizedDescription)")
                continuation.resume()
            })
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("⚠️ Watch WCSession 활성화 실패: \(error.localizedDescription)")
            resumeActivationWaiters(success: false)
            return
        }

        let ok = activationState == .activated
        print("✅ Watch WCSession 활성화 완료 (companionInstalled=\(session.isCompanionAppInstalled), reachable=\(session.isReachable))")
        resumeActivationWaiters(success: ok)

        guard ok else { return }
        if let context = receivedContext(from: session), applyPayloadIfNeeded(context) {
            print("✅ 활성화 직후 applicationContext 식단 적용")
            notifyMealsUpdated()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard !applicationContext.isEmpty else { return }
        if applyPayloadIfNeeded(applicationContext) {
            print("✅ didReceiveApplicationContext 식단 적용")
            notifyMealsUpdated()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard !userInfo.isEmpty else { return }
        if applyPayloadIfNeeded(userInfo) {
            print("✅ didReceiveUserInfo 식단 적용")
            notifyMealsUpdated()
        }
    }

    // MARK: - Private

    @discardableResult
    private func applyPayloadIfNeeded(_ payload: [String: Any]) -> Bool {
        guard !payload.isEmpty,
              let meals = WatchMealSync.meals(from: payload),
              !meals.isEmpty
        else { return false }
        return AppGroupMealCache.save(Calendar.kstMealsInWeek(from: meals))
    }

    private func receivedContext(from session: WCSession) -> [String: Any]? {
        guard session.activationState == .activated else { return nil }
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return nil }
        return context
    }

    private func notifyMealsUpdated() {
        let handler: (@MainActor @Sendable () -> Void)?
        stateLock.lock()
        handler = mealsUpdatedHandler
        stateLock.unlock()
        guard let handler else { return }
        Task { @MainActor in
            handler()
        }
    }

    private func resumeActivationWaiters(success: Bool) {
        stateLock.lock()
        let waiters = activationContinuations
        activationContinuations.removeAll()
        stateLock.unlock()
        waiters.forEach { $0.resume(returning: success) }
    }
}
