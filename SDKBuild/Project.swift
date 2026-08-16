import ProjectDescription

// Not part of the app workspace. This project exists for one purpose: to
// compile CryptoCoreKit's Swift wrapper together with the Rust core into a
// single closed-source .framework per platform slice (device + simulator),
// which get combined into CryptoCoreKit.xcframework via `xcodebuild
// -create-xcframework`. Consumers of the resulting SDK package see only a
// compiled binary and its public .swiftinterface — no .swift source ships.
let project = Project(
    name: "CryptoCoreKitSDKBuild",
    targets: [
        .target(
            name: "CryptoCoreKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.cryptocorekit",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .xcframework(path: "../crypto_core/crypto_core.xcframework")
            ],
            settings: .settings(base: [
                "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                "SKIP_INSTALL": "NO",
            ])
        )
    ]
)
