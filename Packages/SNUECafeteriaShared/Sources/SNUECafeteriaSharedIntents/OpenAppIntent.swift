//
//  OpenAppIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation
import SNUECafeteriaShared

extension Notification.Name {
    public nonisolated static let openAppTab = Notification.Name("openAppTab")
}

public enum AppTabSelection: String, AppEnum {
    case today
    case week
    case settings

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "화면"
    public static let caseDisplayRepresentations: [AppTabSelection: DisplayRepresentation] = [
        .today: "오늘",
        .week: "주간",
        .settings: "설정",
    ]
}

public struct OpenAppIntent: AppIntent {
    public init() {}

    public static let title: LocalizedStringResource = "앱 열기"
    public static let description = IntentDescription("앱을 선택한 화면으로 엽니다.")

    public static let openAppWhenRun: Bool = true

    @Parameter(title: "화면", default: AppTabSelection.today, requestValueDialog: "어느 화면을 여시겠어요?")
    public var tab: AppTabSelection

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$tab) 탭 열기")
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(tab.rawValue, forKey: AppGroupsConfig.NavigationKeys.pendingNavigationTab)
        await MainActor.run {
            NotificationCenter.default.post(name: .openAppTab, object: tab.rawValue)
        }
        let name: String
        switch tab {
        case .today: name = "오늘"
        case .week: name = "주간"
        case .settings: name = "설정"
        }
        return .result(dialog: "\(name) 화면을 엽니다.")
    }
}
