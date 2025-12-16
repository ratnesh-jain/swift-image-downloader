//
//  File.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 16/12/25.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct DefaultDownloadClient: Sendable {
    public var download: @Sendable (_ url: URL) async throws -> Data
}

extension DefaultDownloadClient: DependencyKey {
    public static let liveValue: DefaultDownloadClient = {
        DefaultDownloadClient { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    }()
    
    public static var testValue: DefaultDownloadClient {
        DefaultDownloadClient { url in
            reportIssue("Unimplemented: @Dependency(\\.defaultDownloadClient)")
            return Data()
        }
    }
}

extension DependencyValues {
    public var defaultDownloader: DefaultDownloadClient {
        get { self[DefaultDownloadClient.self] }
        set { self[DefaultDownloadClient.self] = newValue }
    }
}
