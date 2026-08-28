//
//  MealShareRelayService.swift
//  Shared
//

import Foundation

extension Notification.Name {
    static let watchShareRelayReceived = Notification.Name("watchShareRelayReceived")
}

/// iPhone에서 Watch 공유 페이로드를 수신해 SharePreviewSheet로 넘긴다.
/// Watch → iPhone 전송은 WCSession.sendMessage 경로에서 크래시가 발생해 제거했다.
/// 향후 푸시 서버 릴레이로 대체 예정.
enum MealShareRelayService {
    /// iPhone에서 Watch가 보낸 userInfo / message를 처리한다.
    @discardableResult
    static func handleIncoming(_ dictionary: [String: Any]) -> Bool {
        guard let data = payloadData(from: dictionary),
              let payload = try? JSONDecoder().decode(MealShareRelayPayload.self, from: data)
        else { return false }

        Task { @MainActor in
            PendingWatchShareStore.shared.enqueue(payload)
            NotificationCenter.default.post(name: .watchShareRelayReceived, object: payload)
        }
        return true
    }

    private static func payloadData(from dictionary: [String: Any]) -> Data? {
        if let data = dictionary[MealShareRelayKeys.payload] as? Data {
            return data
        }
        if let base64 = dictionary[MealShareRelayKeys.payload] as? String {
            return Data(base64Encoded: base64)
        }
        return nil
    }
}

@MainActor
@Observable
final class PendingWatchShareStore {
    static let shared = PendingWatchShareStore()

    private(set) var pending: MealShareRelayPayload?

    func enqueue(_ payload: MealShareRelayPayload) {
        pending = payload
    }

    func consume() -> MealShareRelayPayload? {
        defer { pending = nil }
        return pending
    }
}

#if os(iOS)
import WatchConnectivity
import WatchConnectivityKit

/// WatchConnectivityKit이 WCSession delegate를 소유하므로, 공유 수신을 위해 delegate를 중계한다.
final class MealShareRelayBridge: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = MealShareRelayBridge()

    private let phoneSync = PhoneWatchSyncService.shared

    func install() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        phoneSync.session(session, activationDidCompleteWith: activationState, error: error)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        phoneSync.sessionDidBecomeInactive(session)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        phoneSync.sessionDidDeactivate(session)
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        phoneSync.sessionWatchStateDidChange(session)
        // PhoneWatchSyncService.activate()가 delegate를 다시 가져가므로 bridge를 복구한다.
        install()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        if MealShareRelayService.handleIncoming(message) {
            replyHandler([:])
            return
        }
        phoneSync.session(session, didReceiveMessage: message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if MealShareRelayService.handleIncoming(userInfo) { return }
    }
}
#endif
