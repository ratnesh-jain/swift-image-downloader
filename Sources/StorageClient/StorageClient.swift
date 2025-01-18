//
//  File.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 18/01/25.
//

import Dependencies
import Foundation

public struct StorageClient: Sendable {
    public var imageCachePath: @Sendable () -> URL
}

extension StorageClient: DependencyKey {
    public static let liveValue: StorageClient = .init {
        URL.documentsDirectory.appending(path: "Images")
    }
}

extension DependencyValues {
    public var storageClient: StorageClient {
        get { self[StorageClient.self] }
        set { self[StorageClient.self] = newValue }
    }
}
