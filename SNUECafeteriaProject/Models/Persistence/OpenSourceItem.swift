//
//  OpenSourceItem.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation

nonisolated struct OpenSourceItem: Identifiable {
    var id = UUID()
    var name: String
    var license: String
    var description: String
    var url: URL
}

extension OpenSourceItem {
    static var items: [OpenSourceItem] {
        [
            OpenSourceItem(
                name: "Firebase SDK (Firestore, AppCheck, Crashlytics)",
                license: "Apache License 2.0",
                description: "애플리케이션의 백엔드 인프라, 실시간 데이터베이스 및 분석을 위한 서비스",
                url: URL(string: "https://github.com/firebase/firebase-ios-sdk")!
            ),
            OpenSourceItem(
                name: "GoogleAppMeasurement",
                license: "Google 서비스 약관",
                description: "애플리케이션 사용량 및 사용자 행동 분석을 위한 도구",
                url: URL(string: "https://developers.google.com/analytics")!
            ),
            OpenSourceItem(
                name: "gRPC",
                license: "Apache License 2.0",
                description: "고성능 RPC(Remote Procedure Call) 프레임워크",
                url: URL(string: "https://github.com/grpc/grpc-swift")!
            ),
            OpenSourceItem(
                name: "abseil",
                license: "Apache License 2.0",
                description: "C++ 표준 라이브러리를 보완하는 오픈소스 코드 모음",
                url: URL(string: "https://github.com/abseil/abseil-cpp")!
            ),
            OpenSourceItem(
                name: "Promises",
                license: "Apache License 2.0",
                description: "Swift 및 Objective-C를 위한 동기화 처리를 돕는 프레임워크",
                url: URL(string: "https://github.com/google/promises")!
            ),
            OpenSourceItem(
                name: "leveldb",
                license: "BSD-3-Clause",
                description: "빠른 키-값 저장소 라이브러리 (Firestore의 데이터 캐싱 등에 사용)",
                url: URL(string: "https://github.com/google/leveldb")!
            ),
            OpenSourceItem(
                name: "nanopb",
                license: "Zlib",
                description: "메모리 사용량이 적은 Protocol Buffers 구현체",
                url: URL(string: "https://github.com/nanopb/nanopb")!
            )
        ]
    }
}
