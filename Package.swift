// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target.Dependency {
    static var fetchingView: Self {
        .product(name: "FetchingView", package: "swiftui-fetching-view")
    }
}

let package = Package(
    name: "SwiftImageDownloader",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(
            name: "ImageDownloader",
            targets: ["ImageDownloader"]
        ),
        .library(
            name: "AsyncImageView",
            targets: ["AsyncImageView"]
        ),
        .library(
            name: "AppAsyncImage",
            targets: ["AppAsyncImage"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ratnesh-jain/swiftui-fetching-view",
            .upToNextMajor(from: "0.1.0")
        )
    ],
    targets: [
        .target(name: "ImageDownloader"),
        .target(name: "AsyncImageView", dependencies: ["ImageDownloader"]),
        .target(name: "AppAsyncImage", dependencies: [.fetchingView, "ImageDownloader"]),
    ]
)
