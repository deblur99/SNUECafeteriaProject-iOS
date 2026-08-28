//
//  ServiceContainer.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 6/5/26.
//

import Foundation
import NetworkMonitorKit

/// 앱 계층에서 생성하여 SwiftUI 환경에 주입하는 의존성 컨테이너.
/// 뷰는 @Environment(ServiceContainer.self)로 필요한 서비스에 접근한다.
@MainActor
@Observable
final class ServiceContainer {
    let notification: NotificationService
    let network: NetworkMonitor

    init(
        notification: NotificationService = NotificationService(),
        network: NetworkMonitor = NetworkMonitor()
    ) {
        self.notification = notification
        self.network = network
    }
}
