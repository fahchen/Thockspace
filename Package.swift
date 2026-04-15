// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Thockspace",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Thockspace",
            path: "Thockspace",
            exclude: ["Resources", "Info.plist", "Thockspace.entitlements"],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
    ]
)
