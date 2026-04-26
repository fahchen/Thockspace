// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Thockspace",
    platforms: [.macOS(.v26)],
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
