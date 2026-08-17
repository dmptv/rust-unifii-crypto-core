// swift-tools-version: 6.2
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Sharing": .framework
    ],
    baseSettings: .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
    targetSettings: [
        // TCA's macro plugin target declares macOS 13, below SwiftSyntax's
        // (its own dependency) minimum of macOS 15 on this toolchain.
        "ComposableArchitectureMacros": ["MACOSX_DEPLOYMENT_TARGET": "15.0"],
        "ComposableArchitecture": ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"],
        // SwiftProtobuf no longer appears here: it's vendored (see
        // ../../SwiftProtobufVendored) specifically to avoid the same
        // class of bug on its synthesized resource-bundle target, which
        // targetSettings can't reach by name at all.
        "CombineSchedulers": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "CasePaths": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "CasePathsCore": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Clocks": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "InternalCollectionsUtilities": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0"
        ],
        "OrderedCollections": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "ConcurrencyExtras": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "CustomDump": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Dependencies": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "IdentifiedCollections": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftNavigation": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftPerception": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSharing": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "XCTestDynamicOverlay": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftBasicFormat": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "CasePathsMacros": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "CasePathsMacrosSupport": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftCompilerPlugin": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftCompilerPluginMessageHandling": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftDiagnostics": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftIfConfig": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftOperators": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftParser": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftParserDiagnostics": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax509": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax510": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax600": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax601": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax602": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntax603": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntaxBuilder": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntaxMacroExpansion": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftSyntaxMacros": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "_SwiftSyntaxCShims": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Perception": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "PerceptionCore": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "PerceptionMacros": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Sharing": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Sharing1": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "Sharing2": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "IssueReporting": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "DependenciesMacros": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "DependenciesMacrosPlugin": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftNavigationMacros": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "SwiftUINavigation": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "UIKitNavigation": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
        "UIKitNavigationShim": [
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0"
        ],
    ]
)
#endif

let package = Package(
    name: "CryptoCoreAppDependencies",
    platforms: [.iOS(.v26)],
    dependencies: [
        .package(path: "../../CryptoCoreKitSDK"),
        .package(path: "../../ElizaProtoKit"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.26.1"),
    ]
)
