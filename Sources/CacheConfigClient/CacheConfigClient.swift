//
//  File.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 18/01/25.
//

import Dependencies
import Foundation

public struct CacheConfigClient: Sendable {
    public var allowCache: @Sendable () -> Bool
    public var countLimit: @Sendable () -> Int
    public var totalCostLimit: @Sendable () -> Int
}

extension CacheConfigClient: DependencyKey {
    public static let liveValue: CacheConfigClient = .init {
        return true
    } countLimit: {
        return 0
    } totalCostLimit: {
        return 0
    }
}

extension DependencyValues {
    public var imageCacheConfig: CacheConfigClient {
        get { self[CacheConfigClient.self] }
        set { self[CacheConfigClient.self] = newValue }
    }
    
    public var colorCacheConfig: CacheConfigClient {
        get { self[CacheConfigClient.self] }
        set { self[CacheConfigClient.self] = newValue }
    }
}
