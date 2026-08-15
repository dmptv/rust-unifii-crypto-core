import ProjectDescription

let project = Project(
    name: "CryptoCoreApp",
    targets: [
        .target(
            name: "CryptoCoreApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.cryptocoreapp",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .xcframework(path: "../crypto_core/crypto_core.xcframework")
            ]
        )
    ]
)
