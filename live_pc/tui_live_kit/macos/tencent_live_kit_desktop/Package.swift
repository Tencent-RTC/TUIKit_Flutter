// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "tencent_live_kit_desktop",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "tencent-live-kit-desktop", targets: ["tencent_live_kit_desktop"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "tencent_live_kit_desktop",
            path: "Sources/tui_live_kit",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
