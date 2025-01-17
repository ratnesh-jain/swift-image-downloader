//
//  AppImageDownloader.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//

import Foundation

/// A single-ton access point for the `ImageDownloader` actor.
public enum AppImageDownloader {
    static let downloader = ImageDownloader()
    
    @discardableResult
    nonisolated public static func download(url: URL) async throws -> PlatformImage {
        try await downloader.download(url: url)
    }
    
    public static func cancel(url: URL) async {
        await downloader.cancel(url: url)
    }
    
    public static func downloadAndCache(urls: [URL]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try await downloader.download(url: url)
                }
            }
            try await group.waitForAll()
        }
    }
    
    public static func clearCache(urls: [URL]) async {
        await downloader.clearCache(urls: urls)
    }
    
    public static func color(for url: URL) async -> ColorValue? {
        await downloader.imageColor(for: url)
    }
}
