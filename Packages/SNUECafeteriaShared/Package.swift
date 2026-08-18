// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SNUECafeteriaShared",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "SNUECafeteriaShared",
            targets: ["SNUECafeteriaShared"]
        ),
        .library(
            name: "SNUECafeteriaSharedIntents",
            targets: ["SNUECafeteriaSharedIntents"]
        ),
        .library(
            name: "SNUECafeteriaSharedWatchBridge",
            targets: ["SNUECafeteriaSharedWatchBridge"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/deblur99/WatchConnectivityKit.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SNUECafeteriaShared",
            dependencies: [],
            path: "Sources/SNUECafeteriaShared",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "SNUECafeteriaSharedIntents",
            dependencies: ["SNUECafeteriaShared"],
            path: "Sources/SNUECafeteriaSharedIntents",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "SNUECafeteriaSharedWatchBridge",
            dependencies: [
                "SNUECafeteriaShared",
                .product(name: "WatchConnectivityKit", package: "WatchConnectivityKit"),
            ],
            path: "Sources/SNUECafeteriaSharedWatchBridge",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SNUECafeteriaSharedTests",
            dependencies: ["SNUECafeteriaShared"],
            path: "Tests/SNUECafeteriaSharedTests"
        ),
    ]
)
