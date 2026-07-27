//
//  NetworkService.swift
//  SNUECafeteriaProject
//

import Foundation
import Network
import os

nonisolated final class NetworkService: Sendable {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.snuecafeteria.network-monitor")

    private let _isReady: OSAllocatedUnfairLock<Bool> = .init(initialState: false)
    private let _isConnected: OSAllocatedUnfairLock<Bool> = .init(initialState: false)

    init() {
        monitor.pathUpdateHandler = { [_isReady, _isConnected] path in
            _isConnected.withLock { $0 = path.status == .satisfied }
            _isReady.withLock { $0 = true }
        }
        monitor.start(queue: monitorQueue)
    }

    func isConnected() async -> Bool {
        let deadline = Date.now.addingTimeInterval(1.0)
        while Date.now < deadline {
            if _isReady.withLock({ $0 }) {
                return _isConnected.withLock { $0 }
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return _isConnected.withLock { $0 }
    }
}
