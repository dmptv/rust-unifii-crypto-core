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
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageRespectsSafeAreaInsets": false,
                ],
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .xcframework(path: "../crypto_core/crypto_core.xcframework")
            ]
        )
    ]
)
