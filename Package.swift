// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target.Dependency {
    static var fetchingView: Self {
        .product(name: "FetchingView", package: "swiftui-fetching-view")
    }
    static var dependencies: Self {
        .product(name: "Dependencies", package: "swift-dependencies")
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
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            .upToNextMajor(from: "1.0.0")
        )
    ],
    targets: [
        .target(name: "StorageClient", dependencies: [.dependencies]),
        .target(name: "CacheConfigClient", dependencies: [.dependencies]),
        .target(name: "ImageDownloader", dependencies: ["CacheConfigClient", "StorageClient"]),
        .target(name: "AsyncImageView", dependencies: [.fetchingView, "ImageDownloader"]),
        .target(name: "AppAsyncImage", dependencies: [.fetchingView, "ImageDownloader"]),
    ]
)
