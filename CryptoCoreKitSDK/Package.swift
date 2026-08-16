// swift-tools-version: 6.2
import PackageDescription

// A closed-source SDK package: Rust core + Swift wrapper compiled together
// into CryptoCoreKit.xcframework (built via ../SDKBuild). No .swift source
// ships in this package — consumers link the binary and see only its
// public .swiftinterface.
let package = Package(
    name: "CryptoCoreKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CryptoCoreKit", targets: ["CryptoCoreKit"])
    ],
    targets: [
        .binaryTarget(name: "CryptoCoreKit", path: "CryptoCoreKit.xcframework")
    ]
)
