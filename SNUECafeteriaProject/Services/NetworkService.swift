//
//  NetworkService.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation
import Network
import os

nonisolated final class NetworkService: Sendable {
    static let shared = NetworkService()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.snuecafeteria.network-monitor")

    /// 첫 번째 경로 평가 완료 여부
    private let _isReady: OSAllocatedUnfairLock<Bool> = .init(initialState: false)
    /// 마지막으로 평가된 경로 상태
    private let _isConnected: OSAllocatedUnfairLock<Bool> = .init(initialState: false)

    private init() {
        monitor.pathUpdateHandler = { [_isReady, _isConnected] path in
            _isConnected.withLock { $0 = path.status == .satisfied }
            _isReady.withLock { $0 = true }
        }
        monitor.start(queue: monitorQueue)
    }

    /// 현재 네트워크 연결 여부를 반환한다.
    /// NWPathMonitor가 첫 평가를 완료하기 전이면 최대 1초 대기 후 반환한다.
    func isConnected() async -> Bool {
        let deadline = Date.now.addingTimeInterval(1.0)
        while Date.now < deadline {
            if _isReady.withLock({ $0 }) {
                return _isConnected.withLock { $0 }
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        // 1초 내 응답 없으면 연결된 것으로 간주 (false-negative 방지)
        return _isConnected.withLock { $0 }
    }
}
